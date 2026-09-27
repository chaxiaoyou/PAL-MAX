import 'position.dart';

/// Price alerts are evaluated locally against the same snapshots that drive the
/// portfolio, so a rule never needs a server and keeps working offline.
enum AlertKind {
  /// Fires when the price reaches or exceeds [Alert.threshold].
  priceAbove,

  /// Fires when the price falls to or below [Alert.threshold].
  priceBelow,

  /// Fires when the session change percent reaches [Alert.threshold].
  percentChangeAbove,

  /// Falls when the session change percent falls to [Alert.threshold].
  percentChangeBelow,
}

class Alert {
  const Alert({
    required this.id,
    required this.symbol,
    required this.kind,
    required this.threshold,
    required this.createdAt,
    this.enabled = true,
    this.triggeredAt,
    this.note = '',
  });

  final String id;
  final String symbol;
  final AlertKind kind;
  final double threshold;
  final DateTime createdAt;
  final bool enabled;

  /// Set when the rule fires. A triggered rule stays visible but silent until
  /// the user re-arms it, so a price hovering on the threshold does not produce
  /// a notification on every refresh.
  final DateTime? triggeredAt;

  final String note;

  bool get isTriggered => triggeredAt != null;

  /// Ready to fire: enabled and not already fired.
  bool get isArmed => enabled && !isTriggered;

  bool get isPercentKind =>
      kind == AlertKind.percentChangeAbove || kind == AlertKind.percentChangeBelow;

  Alert copyWith({
    AlertKind? kind,
    double? threshold,
    bool? enabled,
    DateTime? triggeredAt,
    bool clearTriggeredAt = false,
    String? note,
  }) {
    return Alert(
      id: id,
      symbol: symbol,
      kind: kind ?? this.kind,
      threshold: threshold ?? this.threshold,
      createdAt: createdAt,
      enabled: enabled ?? this.enabled,
      triggeredAt: clearTriggeredAt ? null : (triggeredAt ?? this.triggeredAt),
      note: note ?? this.note,
    );
  }
}

/// Outcome of checking one rule against the latest price.
class AlertEvaluation {
  const AlertEvaluation({
    required this.alert,
    required this.triggered,
    this.distance,
  });

  final Alert alert;
  final bool triggered;

  /// How far the market still is from the threshold, in the rule's own unit
  /// (price for price rules, percentage points for percent rules). Negative
  /// means the threshold has been crossed. Null when the required input was
  /// missing — a percent rule with no previous close, for instance.
  final double? distance;
}

/// Evaluates one rule. Disarmed rules never fire, and a percent rule without a
/// session change reports `distance: null` rather than guessing.
AlertEvaluation evaluateAlert(
  Alert alert, {
  required double price,
  double? changePercent,
}) {
  if (!alert.isArmed) {
    return AlertEvaluation(alert: alert, triggered: false);
  }

  final (bool triggered, double? distance) = switch (alert.kind) {
    AlertKind.priceAbove => (
        price >= alert.threshold,
        alert.threshold - price,
      ),
    AlertKind.priceBelow => (
        price <= alert.threshold,
        price - alert.threshold,
      ),
    AlertKind.percentChangeAbove => changePercent == null
        ? (false, null)
        : (
            changePercent >= alert.threshold,
            alert.threshold - changePercent,
          ),
    AlertKind.percentChangeBelow => changePercent == null
        ? (false, null)
        : (
            changePercent <= alert.threshold,
            changePercent - alert.threshold,
          ),
  };

  return AlertEvaluation(
    alert: alert,
    triggered: triggered,
    distance: distance,
  );
}

/// Evaluates every current price rule against a batch of snapshots.
///
/// Returns the evaluations in the order of [alerts]; callers persist
/// `triggeredAt` on the ones that fired and re-list the rest.
List<AlertEvaluation> evaluateAlerts(
  Iterable<Alert> alerts,
  Map<String, PriceSnapshot> prices,
) {
  final results = <AlertEvaluation>[];
  for (final alert in alerts) {
    final snapshot = prices[alert.symbol];
    if (snapshot == null) {
      results.add(AlertEvaluation(alert: alert, triggered: false));
      continue;
    }
    results.add(
      evaluateAlert(
        alert,
        price: snapshot.price,
        changePercent: snapshot.hasPreviousClose
            ? snapshot.dayChangePercent
            : null,
      ),
    );
  }
  return results;
}

/// The rules that should notify right now: armed, and with their condition met.
///
/// Separated from [evaluateAlerts] so the notification path has one obvious
/// seam to test, and so the UI can keep showing every rule's distance while
/// only firing the ones that actually crossed.
List<Alert> alertsToFire(
  Iterable<Alert> alerts,
  Map<String, PriceSnapshot> prices,
) {
  return [
    for (final evaluation in evaluateAlerts(alerts, prices))
      if (evaluation.triggered) evaluation.alert,
  ];
}
