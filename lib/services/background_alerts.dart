import 'dart:convert';
import 'dart:ui' show PluginUtilities;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/price_alert.dart';
import '../utils/format.dart';
import 'yahoo_service.dart';

/// Where the app and the Android background job hand the rule set to each
/// other. The payload is opaque to the native side: it only stores the string
/// and hands it back, so the rule format lives in exactly one language.
class AlertRuleCodec {
  static const _channelName = 'NeedhamCapital/alerts';

  static String encode(List<PriceAlert> alerts) => jsonEncode([
        for (final alert in alerts)
          {
            'id': alert.id,
            'symbol': alert.symbol,
            'name': alert.name,
            'direction': alert.direction,
            'threshold': alert.threshold,
            'currency': alert.currency,
            'enabled': alert.enabled,
            'lastAbove': alert.lastAbove,
            'triggeredAt': alert.triggeredAt?.millisecondsSinceEpoch,
            'createdAt': alert.createdAt.millisecondsSinceEpoch,
          },
      ]);

  static List<PriceAlert> decode(String? payload) {
    if (payload == null || payload.isEmpty) return const [];
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];

    final alerts = <PriceAlert>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final symbol = entry['symbol'];
      final direction = entry['direction'];
      final threshold = entry['threshold'];
      if (symbol is! String || direction is! String || threshold is! num) {
        continue;
      }
      final id = entry['id'];
      final triggeredAt = entry['triggeredAt'];
      final createdAt = entry['createdAt'];
      final lastAbove = entry['lastAbove'];
      alerts.add(
        PriceAlert()
          ..id = id is int ? id : 0
          ..symbol = symbol
          ..name = entry['name'] is String ? entry['name'] as String : ''
          ..direction = direction
          ..threshold = threshold.toDouble()
          ..currency = entry['currency'] is String
              ? entry['currency'] as String
              : 'USD'
          ..enabled = entry['enabled'] != false
          ..lastAbove = lastAbove is bool ? lastAbove : null
          ..triggeredAt = triggeredAt is int
              ? DateTime.fromMillisecondsSinceEpoch(triggeredAt)
              : null
          ..createdAt = createdAt is int
              ? DateTime.fromMillisecondsSinceEpoch(createdAt)
              : DateTime.now()
          ..updatedAt = DateTime.now(),
      );
    }
    return alerts;
  }

  static MethodChannel channel() => const MethodChannel(_channelName);

  /// The handle Android needs to start the background entrypoint. Registered
  /// once per launch; without it the periodic job cannot run at all.
  static int? callbackHandle() {
    try {
      return PluginUtilities.getCallbackHandle(alertBackgroundMain)?.toRawHandle();
    } catch (error, stackTrace) {
      debugPrint('alert callback handle unavailable: $error\n$stackTrace');
      return null;
    }
  }
}

/// The wording of a fired alert. Shared so a notification reads the same
/// whether the app was open or the background job found it.
({String title, String body}) alertNotification(PriceAlert alert, double price) {
  return (
    title: '${alert.symbol} crossed '
        '${moneyText(alert.threshold, alert.currency)}',
    body: '${alert.symbol} is now ${moneyText(price, alert.currency)}, '
        '${alert.side.adverb} your alert level.',
  );
}

/// One background check: read the rules, price them, apply the same crossing
/// rule the app uses, and hand back both the updated rules and whatever should
/// be shown.
///
/// Returns the payload it sent, which is what the tests assert on.
Future<Map<String, Object?>> runBackgroundAlertPass({
  required MethodChannel channel,
  required YahooFinanceApi api,
}) async {
  var rules = <PriceAlert>[];
  final notifications = <Map<String, Object?>>[];
  var failed = false;
  try {
    rules = AlertRuleCodec.decode(
      await channel.invokeMethod<String>('readRules'),
    );
    final enabled = [
      for (final rule in rules)
        if (rule.enabled) rule,
    ];
    if (enabled.isNotEmpty) {
      final symbols = {for (final rule in enabled) rule.symbol}.toList();
      final quotes = await api.fetchQuotes(symbols);
      final pass = evaluateAlertRules(
        alerts: rules,
        quotes: {for (final quote in quotes) quote.symbol: quote},
      );
      for (final fired in pass.fired) {
        final message = alertNotification(fired.alert, fired.price);
        notifications.add({
          'id': fired.alert.id,
          'title': message.title,
          'body': message.body,
        });
      }
    }
  } catch (error, stackTrace) {
    // A background pass that cannot get prices must record nothing: leaving the
    // rules untouched just means the next cycle tries again.
    debugPrint('background alert pass failed: $error\n$stackTrace');
    failed = true;
  }

  final payload = <String, Object?>{
    'rules': failed ? null : AlertRuleCodec.encode(rules),
    'notifications': notifications,
  };
  // Android finishes the job only when this arrives, so every outcome reports
  // back — including the ones with nothing to say.
  await channel.invokeMethod<void>('finish', payload);
  return payload;
}

/// Entry point Android starts in a headless engine when the periodic job runs.
///
/// Reached only through [AlertRuleCodec.callbackHandle]; the pragma keeps it
/// alive in release builds, where an unreferenced function would be tree-shaken.
@pragma('vm:entry-point')
Future<void> alertBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final channel = AlertRuleCodec.channel();
  final api = YahooFinanceApi();
  try {
    await runBackgroundAlertPass(channel: channel, api: api);
  } finally {
    api.dispose();
  }
}
