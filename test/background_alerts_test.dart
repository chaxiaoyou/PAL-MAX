import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/price_alert.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/services/background_alerts.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

class _QuotesApi extends YahooFinanceApi {
  _QuotesApi({this.price = 250, this.fails = false});

  final double price;
  final bool fails;
  final requested = <String>[];

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    requested.addAll(symbols);
    if (fails) {
      throw const YahooFinanceException('Quotes request failed with HTTP 429');
    }
    return [
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
}

PriceAlert _alert({
  int id = 7,
  String symbol = 'AAPL',
  AlertDirection direction = AlertDirection.above,
  double threshold = 200,
  bool enabled = true,
  bool? lastAbove = false,
  DateTime? triggeredAt,
}) {
  return PriceAlert()
    ..id = id
    ..symbol = symbol
    ..name = symbol
    ..direction = direction.storageValue
    ..threshold = threshold
    ..currency = 'USD'
    ..enabled = enabled
    ..lastAbove = lastAbove
    ..triggeredAt = triggeredAt
    ..createdAt = DateTime(2026, 1, 1)
    ..updatedAt = DateTime(2026, 1, 1);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final channel = AlertRuleCodec.channel();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Stands in for Android: answers `readRules`, records `finish`.
  Map<Object?, Object?>? finished;

  void mockChannel(String? rules) {
    finished = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'readRules':
          return rules;
        case 'finish':
          finished = call.arguments as Map<Object?, Object?>?;
          return null;
        default:
          return null;
      }
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('AlertRuleCodec', () {
    test('round-trips everything the background check needs', () {
      final triggered = DateTime(2026, 8, 1, 9, 30);
      final encoded = AlertRuleCodec.encode([
        _alert(id: 7, lastAbove: true, triggeredAt: triggered),
        _alert(id: 8, symbol: 'MSFT', direction: AlertDirection.below),
      ]);

      final decoded = AlertRuleCodec.decode(encoded);

      expect(decoded, hasLength(2));
      expect(decoded.first.id, 7);
      expect(decoded.first.symbol, 'AAPL');
      expect(decoded.first.side, AlertDirection.above);
      expect(decoded.first.threshold, 200);
      expect(decoded.first.lastAbove, isTrue);
      expect(decoded.first.triggeredAt, triggered);
      expect(decoded.last.side, AlertDirection.below);
    });

    test('an unreadable payload is no rules rather than an exception', () {
      expect(AlertRuleCodec.decode(null), isEmpty);
      expect(AlertRuleCodec.decode(''), isEmpty);
      expect(AlertRuleCodec.decode('{not json'), isEmpty);
      expect(AlertRuleCodec.decode('[{"symbol":12}]'), isEmpty);
    });
  });

  group('runBackgroundAlertPass', () {
    test('reports the crossing and records the new side', () async {
      mockChannel(AlertRuleCodec.encode([_alert(lastAbove: false)]));
      final api = _QuotesApi(price: 250);

      await runBackgroundAlertPass(channel: channel, api: api);

      final notifications = finished!['notifications'] as List<Object?>;
      expect(notifications, hasLength(1));
      final note = notifications.single as Map<Object?, Object?>;
      expect(note['id'], 7);
      expect(note['title'], 'AAPL crossed \$200.00');
      expect(note['body'], 'AAPL is now \$250.00, above your alert level.');

      // The side is written back so the next cycle does not repeat it.
      final rules = AlertRuleCodec.decode(finished!['rules'] as String?);
      expect(rules.single.lastAbove, isTrue);
    });

    test('says nothing when the price did not cross', () async {
      mockChannel(AlertRuleCodec.encode([_alert(lastAbove: true)]));

      await runBackgroundAlertPass(
        channel: channel,
        api: _QuotesApi(price: 260),
      );

      expect(finished!['notifications'], isEmpty);
      final rules = AlertRuleCodec.decode(finished!['rules'] as String?);
      expect(rules.single.lastAbove, isTrue);
    });

    test('leaves the rules alone when prices cannot be fetched', () async {
      mockChannel(AlertRuleCodec.encode([_alert(lastAbove: false)]));

      await runBackgroundAlertPass(
        channel: channel,
        api: _QuotesApi(fails: true),
      );

      // Recording nothing is the safe outcome: the next cycle retries instead
      // of the app believing a level was checked when it was not.
      expect(finished!['rules'], isNull);
      expect(finished!['notifications'], isEmpty);
    });

    test('does not spend a request on disabled alerts', () async {
      mockChannel(
        AlertRuleCodec.encode([
          _alert(id: 1, symbol: 'AAPL', enabled: false),
          _alert(id: 2, symbol: 'MSFT', enabled: true, lastAbove: false),
        ]),
      );
      final api = _QuotesApi(price: 250);

      await runBackgroundAlertPass(channel: channel, api: api);

      expect(api.requested, ['MSFT']);
      final notifications = finished!['notifications'] as List<Object?>;
      expect(notifications, hasLength(1));
      expect(
        (notifications.single as Map<Object?, Object?>)['id'],
        2,
      );
    });

    test('an empty rule set still reports back, so the job can finish', () async {
      mockChannel(null);

      await runBackgroundAlertPass(
        channel: channel,
        api: _QuotesApi(),
      );

      expect(finished, isNotNull);
      expect(finished!['notifications'], isEmpty);
    });
  });

  test('the app and the background job word a notification identically', () {
    final alert = _alert(lastAbove: false);
    final message = alertNotification(alert, 250);

    expect(message.title, 'AAPL crossed \$200.00');
    expect(message.body, 'AAPL is now \$250.00, above your alert level.');
  });
}
