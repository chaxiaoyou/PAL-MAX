import 'package:flutter/foundation.dart';

import '../domain/alert.dart';
import '../domain/position.dart';
import 'alert_notifier.dart';

/// Builds the localized notification copy for a fired rule.
typedef AlertCopyBuilder = AlertNotification Function(
  Alert alert,
  PriceSnapshot snapshot,
);

/// Turns "these rules are met right now" into notifications, exactly once.
///
/// Kept out of the widget so the interesting behaviour — fire once, do not
/// re-fire, keep going when one rule fails, never post the same rule twice
/// concurrently — is unit-testable with a fake [AlertNotifier] instead of a
/// platform channel.
class AlertDispatcher {
  AlertDispatcher({
    required AlertNotifier notifier,
    required Future<void> Function(Alert alert, DateTime at) markTriggered,
    DateTime Function()? clock,
  })  : _notifier = notifier,
        _markTriggered = markTriggered,
        _clock = clock ?? DateTime.now;

  final AlertNotifier _notifier;
  final Future<void> Function(Alert alert, DateTime at) _markTriggered;
  final DateTime Function() _clock;

  /// Rule ids currently being dispatched, so a slow permission prompt or a
  /// double price refresh cannot post the same alert twice.
  final Set<String> _inFlight = <String>{};

  /// Notifies for every met rule and records the firing time.
  ///
  /// Returns the ids that were dispatched. A rule is marked as fired even when
  /// the user denied notifications: otherwise it would stay armed and re-nag on
  /// every refresh. The in-app list still shows it as triggered.
  Future<List<String>> dispatch({
    required Iterable<Alert> alerts,
    required Map<String, PriceSnapshot> prices,
    required AlertCopyBuilder buildCopy,
  }) async {
    final dispatched = <String>[];

    for (final alert in alertsToFire(alerts, prices)) {
      final snapshot = prices[alert.symbol];
      if (snapshot == null) continue;
      if (!_inFlight.add(alert.id)) continue;
      try {
        final granted = await _notifier.ensurePermission();
        if (granted) {
          await _notifier.show(alert.id.hashCode, buildCopy(alert, snapshot));
        }
        await _markTriggered(alert, _clock());
        dispatched.add(alert.id);
      } catch (error, stackTrace) {
        // One broken rule must not stop the rest from firing.
        debugPrint('alert dispatch failed for ${alert.id}: $error\n$stackTrace');
      } finally {
        _inFlight.remove(alert.id);
      }
    }

    return dispatched;
  }
}
