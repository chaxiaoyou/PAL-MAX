import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/price_alert.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/services/alert_notifier.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

/// Records what would have been delivered.
class _RecordingAlertNotifier implements AlertNotifier {
  final notifications = <String>[];
  var allowed = true;
  var permissionRequests = 0;

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<void> notify({
    required int id,
    required String title,
    required String body,
  }) async {
    notifications.add('$title|$body');
  }
}

class _QuotesApi extends YahooFinanceApi {
  _QuotesApi(this.price);

  double price;

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => [
        for (final symbol in symbols)
          Quote(
            symbol: symbol,
            name: symbol,
            lastPrice: price,
            change: 1,
            changePercent: 1,
          ),
      ];
}

PriceAlert _alert({
  String symbol = 'AAPL',
  AlertDirection direction = AlertDirection.above,
  double threshold = 200,
  bool enabled = true,
  bool? lastAbove,
}) {
  return PriceAlert()
    ..symbol = symbol
    ..name = symbol
    ..direction = direction.storageValue
    ..threshold = threshold
    ..currency = 'USD'
    ..enabled = enabled
    ..lastAbove = lastAbove
    ..createdAt = DateTime(2026, 1, 1)
    ..updatedAt = DateTime(2026, 1, 1);
}

Future<void> _settle() async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('PriceAlert.check', () {
    test('does not fire on the first observation, whichever side it is on', () {
      expect(_alert(threshold: 200).check(250).shouldNotify, isFalse);
      expect(_alert(threshold: 200).check(150).shouldNotify, isFalse);
      // The first check still records the side the price was on.
      expect(_alert(threshold: 200).check(250).isAbove, isTrue);
      expect(_alert(threshold: 200).check(150).isAbove, isFalse);
    });

    test('an above alert fires only when the price crosses up', () {
      final below = _alert(threshold: 200, lastAbove: false);
      expect(below.check(250).shouldNotify, isTrue);

      final above = _alert(threshold: 200, lastAbove: true);
      // Still above the level: no repeat buzz on every refresh.
      expect(above.check(260).shouldNotify, isFalse);
      expect(above.check(260).isAbove, isTrue);
    });

    test('a below alert fires only when the price crosses down', () {
      final above = _alert(
        threshold: 200,
        direction: AlertDirection.below,
        lastAbove: true,
      );
      expect(above.check(180).shouldNotify, isTrue);

      final below = _alert(
        threshold: 200,
        direction: AlertDirection.below,
        lastAbove: false,
      );
      expect(below.check(150).shouldNotify, isFalse);
    });

    test('a disabled alert never fires', () {
      final alert = _alert(threshold: 200, enabled: false, lastAbove: false);
      expect(alert.check(250).shouldNotify, isFalse);
    });

    test('a price exactly on the level counts as not above', () {
      final alert = _alert(threshold: 200, lastAbove: true);
      final check = alert.check(200);
      expect(check.isAbove, isFalse);
      // Down to exactly the level is not a crossing below it.
      expect(check.shouldNotify, isFalse);
    });
  });

  group('AlertsNotifier', () {
    late _RecordingAlertNotifier notifier;
    late _QuotesApi api;
    late ProviderContainer container;

    /// Starts below every level used here, so the assertions measure the price
    /// moving across a threshold rather than the app's first quote on launch.
    Future<void> quoteAt(double price) async {
      api.price = price;
      await container.read(quoteBoardProvider.notifier).refresh();
      await _settle();
    }

    Future<void> open({required List<PriceAlert> alerts}) async {
      final store = await openStore('alerts_test', alerts: alerts);
      notifier = _RecordingAlertNotifier();
      api = _QuotesApi(150);
      container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(store),
          yahooApiProvider.overrideWithValue(api),
          alertNotifierProvider.overrideWithValue(notifier),
        ],
      );
      addTearDown(container.dispose);
      container.read(alertsProvider);
      container.read(watchlistProvider);
      await _settle();
    }

    test(
      'fires once when a fresh alert sees the price cross',
      () async {
        // lastAbove is false, then the price moves above the level.
        await open(alerts: [_alert(threshold: 200, lastAbove: false)]);
        expect(notifier.notifications, isEmpty);

        await quoteAt(250);
        expect(notifier.notifications, hasLength(1));
        expect(notifier.notifications.single, contains('AAPL crossed'));

        // A second refresh at the same price must stay quiet.
        await quoteAt(255);
        expect(notifier.notifications, hasLength(1));

        // The crossing is persisted, so a restart does not repeat it.
        final stored = container.read(alertsProvider).alerts.single;
        expect(stored.lastAbove, isTrue);
        expect(stored.triggeredAt, isNotNull);
      },
      skip: isarUnavailable,
    );

    test(
      'stays quiet while the price never crosses',
      () async {
        await open(alerts: [_alert(threshold: 200, lastAbove: true)]);
        await quoteAt(150);

        expect(notifier.notifications, isEmpty);
      },
      skip: isarUnavailable,
    );

    test(
      're-arms when the level is edited',
      () async {
        await open(alerts: [_alert(threshold: 200, lastAbove: true)]);
        final existing = container.read(alertsProvider).alerts.single;

        // A new level has an unknown side until the next quote arrives.
        await container.read(alertsProvider.notifier).save(
              const PriceAlertDraft(
                symbol: 'AAPL',
                name: 'Apple Inc.',
                direction: AlertDirection.below,
                threshold: 260,
                currency: 'USD',
              ),
              existing: existing,
            );
        final edited = container.read(alertsProvider).alerts.single;
        expect(edited.lastAbove, isNull);
        expect(edited.side, AlertDirection.below);

        // 250 is now below the 260 level, but the first look only records it.
        await quoteAt(250);
        expect(notifier.notifications, isEmpty);
        expect(container.read(alertsProvider).alerts.single.lastAbove, isFalse);
      },
      skip: isarUnavailable,
    );

    test(
      're-arms when an alert is switched back on',
      () async {
        await open(alerts: [_alert(threshold: 200, lastAbove: false)]);
        var alert = container.read(alertsProvider).alerts.single;

        await container.read(alertsProvider.notifier).setEnabled(alert, false);
        // A crossing while it is off is not something the user asked to hear.
        await quoteAt(250);
        expect(notifier.notifications, isEmpty);

        alert = container.read(alertsProvider).alerts.single;
        await container.read(alertsProvider.notifier).setEnabled(alert, true);
        expect(container.read(alertsProvider).alerts.single.lastAbove, isNull);

        // Re-armed means the next quote is an observation again, not a
        // crossing, so re-enabling something already past its level stays
        // quiet until the price actually crosses.
        await quoteAt(250);
        expect(notifier.notifications, isEmpty);
        expect(container.read(alertsProvider).alerts.single.lastAbove, isTrue);

        // A dip and a fresh push through the level is the crossing.
        await quoteAt(150);
        await quoteAt(250);
        expect(notifier.notifications, hasLength(1));
      },
      skip: isarUnavailable,
    );

    test(
      'asks for permission and reports the answer',
      () async {
        await open(alerts: []);
        notifier.allowed = false;
        expect(container.read(alertsProvider).notificationsAllowed, isTrue);

        final allowed =
            await container.read(alertsProvider.notifier).requestPermission();
        expect(allowed, isFalse);
        expect(notifier.permissionRequests, 1);
        expect(container.read(alertsProvider).notificationsAllowed, isFalse);
      },
      skip: isarUnavailable,
    );
  });
}
