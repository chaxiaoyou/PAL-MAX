import 'package:flutter_test/flutter_test.dart';
import 'package:pjza/data/portfolio_store.dart';
import 'package:pjza/domain/alert.dart';
import 'package:pjza/domain/position.dart';
import 'package:pjza/services/alert_dispatcher.dart';
import 'package:pjza/services/alert_notifier.dart';

/// Stands in for the platform plugin and records what would have been posted.
class RecordingAlertNotifier implements AlertNotifier {
  RecordingAlertNotifier({this.granted = true, this.throwOnShow = false});

  bool granted;
  bool throwOnShow;
  final List<int> shown = [];
  final List<AlertNotification> notifications = [];
  int permissionChecks = 0;

  @override
  Future<bool> ensurePermission() async {
    permissionChecks++;
    return granted;
  }

  @override
  Future<void> show(int id, AlertNotification notification) async {
    if (throwOnShow) throw StateError('notification failed');
    shown.add(id);
    notifications.add(notification);
  }
}

Alert rule(
  String id,
  AlertKind kind,
  double threshold, {
  String symbol = 'WALMEX.MX',
}) {
  return Alert(
    id: id,
    symbol: symbol,
    kind: kind,
    threshold: threshold,
    createdAt: DateTime(2026, 6, 1),
  );
}

Map<String, PriceSnapshot> prices({
  double price = 155,
  double previousClose = 150,
  String symbol = 'WALMEX.MX',
}) {
  return {
    symbol: PriceSnapshot(
      symbol: symbol,
      price: price,
      previousClose: previousClose,
      asOf: DateTime(2026, 7, 1),
    ),
  };
}

AlertNotification copy(Alert alert, PriceSnapshot snapshot) => AlertNotification(
      title: '${alert.symbol} alert',
      body: '${alert.threshold} — ${snapshot.price}',
      channelName: 'Price alerts',
      channelDescription: 'Tells you when a rule is met.',
    );

void main() {
  group('AlertDispatcher', () {
    test('posts a notification for a met rule and records the firing', () async {
      final notifier = RecordingAlertNotifier();
      final fired = <String>[];
      final dispatcher = AlertDispatcher(
        notifier: notifier,
        markTriggered: (alert, at) async => fired.add(alert.id),
        clock: () => DateTime(2026, 7, 1, 12),
      );

      final dispatched = await dispatcher.dispatch(
        alerts: [rule('a', AlertKind.priceAbove, 150)],
        prices: prices(),
        buildCopy: copy,
      );

      expect(dispatched, ['a']);
      expect(notifier.shown, hasLength(1));
      expect(fired, ['a']);
      expect(notifier.notifications.single.title, contains('WALMEX.MX'));
    });

    test('leaves rules whose condition is not met alone', () async {
      final notifier = RecordingAlertNotifier();
      final dispatcher = AlertDispatcher(
        notifier: notifier,
        markTriggered: (alert, at) async {},
      );

      final dispatched = await dispatcher.dispatch(
        alerts: [rule('a', AlertKind.priceBelow, 100)],
        prices: prices(),
        buildCopy: copy,
      );

      expect(dispatched, isEmpty);
      expect(notifier.shown, isEmpty);
      expect(notifier.permissionChecks, 0);
    });

    test('a rule already marked as fired never notifies again', () async {
      final store = InMemoryPortfolioStore(
        alerts: [rule('a', AlertKind.priceAbove, 150)],
      );
      final alerts = AlertsNotifier(store);
      // Let the notifier's async load land.
      await Future<void>.delayed(Duration.zero);

      final notifier = RecordingAlertNotifier();
      final dispatcher = AlertDispatcher(
        notifier: notifier,
        markTriggered: alerts.markTriggered,
      );

      await dispatcher.dispatch(
        alerts: alerts.state,
        prices: prices(),
        buildCopy: copy,
      );
      expect(notifier.shown, hasLength(1));

      // The next refresh sees the persisted fired marker and stays quiet.
      final second = await dispatcher.dispatch(
        alerts: alerts.state,
        prices: prices(),
        buildCopy: copy,
      );

      expect(second, isEmpty);
      expect(notifier.shown, hasLength(1));

      // Re-arming makes it live again.
      await alerts.reArm(alerts.state.single);
      await dispatcher.dispatch(
        alerts: alerts.state,
        prices: prices(),
        buildCopy: copy,
      );
      expect(notifier.shown, hasLength(2));
    });

    test('still records the firing when notifications are denied', () async {
      final notifier = RecordingAlertNotifier(granted: false);
      final fired = <String>[];
      final dispatcher = AlertDispatcher(
        notifier: notifier,
        markTriggered: (alert, at) async => fired.add(alert.id),
      );

      await dispatcher.dispatch(
        alerts: [rule('a', AlertKind.priceAbove, 150)],
        prices: prices(),
        buildCopy: copy,
      );

      expect(notifier.shown, isEmpty);
      // Without this the rule would re-evaluate as armed on every refresh.
      expect(fired, ['a']);
    });

    test('one failing rule does not stop the others', () async {
      final notifier = RecordingAlertNotifier(throwOnShow: true);
      final fired = <String>[];
      final dispatcher = AlertDispatcher(
        notifier: notifier,
        markTriggered: (alert, at) async => fired.add(alert.id),
      );

      await dispatcher.dispatch(
        alerts: [
          rule('a', AlertKind.priceAbove, 150),
          rule('b', AlertKind.priceAbove, 120),
        ],
        prices: prices(),
        buildCopy: copy,
      );

      // Neither rule is marked as fired, because the notification threw before
      // the marker was written; the important part is that b was still tried.
      expect(fired, isEmpty);
      expect(notifier.permissionChecks, 2);
    });
  });

  group('alertsToFire', () {
    test('returns only armed rules with a met condition', () {
      final toFire = alertsToFire([
        rule('met', AlertKind.priceAbove, 150),
        rule('not-met', AlertKind.priceAbove, 200),
        rule('paused', AlertKind.priceAbove, 100).copyWith(enabled: false),
        rule('fired', AlertKind.priceAbove, 100)
            .copyWith(triggeredAt: DateTime(2026, 6, 30)),
      ], prices());

      expect(toFire.map((alert) => alert.id).toList(), ['met']);
    });

    test('ignores rules whose symbol has no price yet', () {
      final toFire = alertsToFire(
        [rule('a', AlertKind.priceAbove, 150, symbol: 'FEMSAUBD.MX')],
        prices(),
      );

      expect(toFire, isEmpty);
    });
  });
}
