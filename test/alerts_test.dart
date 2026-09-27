import 'package:flutter_test/flutter_test.dart';
import 'package:pjza/domain/alert.dart';
import 'package:pjza/domain/position.dart';

Alert rule(
  AlertKind kind,
  double threshold, {
  String symbol = 'WALMEX',
  bool enabled = true,
  DateTime? triggeredAt,
}) {
  return Alert(
    id: 'a1',
    symbol: symbol,
    kind: kind,
    threshold: threshold,
    createdAt: DateTime(2026, 1, 1),
    enabled: enabled,
    triggeredAt: triggeredAt,
  );
}

void main() {
  group('evaluateAlert', () {
    test('price above fires at and beyond the threshold', () {
      final alert = rule(AlertKind.priceAbove, 150);

      expect(evaluateAlert(alert, price: 149.99).triggered, isFalse);
      expect(evaluateAlert(alert, price: 150).triggered, isTrue);
      expect(evaluateAlert(alert, price: 160).triggered, isTrue);
    });

    test('price below fires at and under the threshold', () {
      final alert = rule(AlertKind.priceBelow, 100);

      expect(evaluateAlert(alert, price: 100.01).triggered, isFalse);
      expect(evaluateAlert(alert, price: 100).triggered, isTrue);
      expect(evaluateAlert(alert, price: 90).triggered, isTrue);
    });

    test('distance stays positive while the trigger is still ahead', () {
      final above = evaluateAlert(rule(AlertKind.priceAbove, 150), price: 140);
      expect(above.distance, closeTo(10, 1e-9));

      final below = evaluateAlert(rule(AlertKind.priceBelow, 100), price: 110);
      expect(below.distance, closeTo(10, 1e-9));

      final crossed = evaluateAlert(rule(AlertKind.priceAbove, 150), price: 155);
      expect(crossed.distance, closeTo(-5, 1e-9));
    });

    test('percent rules need a session change to judge', () {
      final alert = rule(AlertKind.percentChangeAbove, 5);

      final unknown = evaluateAlert(alert, price: 100);
      expect(unknown.triggered, isFalse);
      expect(unknown.distance, isNull);

      expect(
        evaluateAlert(alert, price: 100, changePercent: 4.5).triggered,
        isFalse,
      );
      expect(
        evaluateAlert(alert, price: 100, changePercent: 5).triggered,
        isTrue,
      );
    });

    test('a percent drop rule fires on the way down', () {
      final alert = rule(AlertKind.percentChangeBelow, -3);

      expect(
        evaluateAlert(alert, price: 100, changePercent: -2.9).triggered,
        isFalse,
      );
      expect(
        evaluateAlert(alert, price: 100, changePercent: -3.1).triggered,
        isTrue,
      );
    });

    test('disabled and already-triggered rules stay silent', () {
      final disabled = rule(AlertKind.priceAbove, 100, enabled: false);
      expect(disabled.isArmed, isFalse);
      expect(evaluateAlert(disabled, price: 200).triggered, isFalse);

      final fired = rule(
        AlertKind.priceAbove,
        100,
        triggeredAt: DateTime(2026, 2, 1),
      );
      expect(fired.isTriggered, isTrue);
      expect(fired.isArmed, isFalse);
      // Re-checking a fired rule must not notify again.
      expect(evaluateAlert(fired, price: 200).triggered, isFalse);

      // Re-arming makes it live again.
      final rearmed = fired.copyWith(clearTriggeredAt: true);
      expect(rearmed.isArmed, isTrue);
      expect(evaluateAlert(rearmed, price: 200).triggered, isTrue);
    });
  });

  group('evaluateAlerts', () {
    Map<String, PriceSnapshot> prices() => {
          'WALMEX': PriceSnapshot(
            symbol: 'WALMEX',
            price: 155,
            previousClose: 150,
            asOf: DateTime(2026, 2, 1),
          ),
        };

    test('evaluates each rule against its own symbol', () {
      final results = evaluateAlerts([
        rule(AlertKind.priceAbove, 150),
        rule(AlertKind.priceBelow, 150),
        rule(AlertKind.percentChangeAbove, 2),
      ], prices());

      expect(results.map((r) => r.triggered).toList(), [true, false, true]);
    });

    test('rules for unpriced symbols are reported as not triggered', () {
      final results = evaluateAlerts([
        rule(AlertKind.priceAbove, 150, symbol: 'FEMSA'),
      ], prices());

      expect(results.single.triggered, isFalse);
      expect(results.single.distance, isNull);
    });
  });
}
