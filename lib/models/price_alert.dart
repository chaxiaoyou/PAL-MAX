import 'package:isar_community/isar.dart';

import 'quote.dart';

part 'price_alert.g.dart';

enum AlertDirection {
  above('above', 'Above'),
  below('below', 'Below');

  const AlertDirection(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static AlertDirection fromStorage(String? value) =>
      value == below.storageValue ? below : above;

  /// `rises above` / `falls below`, for one-line summaries.
  String get phrase => this == above ? 'rises above' : 'falls below';

  /// `above` / `below`, for sentences.
  String get adverb => this == above ? 'above' : 'below';
}

/// What a single quote check concluded.
class AlertCheck {
  const AlertCheck({required this.shouldNotify, required this.isAbove});

  final bool shouldNotify;

  /// Which side of the threshold the price was on during this check.
  final bool isAbove;
}

/// A price level the user wants to hear about.
///
/// The alert fires on a *crossing*, never on a level that is merely still met:
/// the first observation only records which side the price is on, so creating
/// an alert whose level has already been reached does not buzz the phone
/// immediately, and a price that sits above the level for a week does not fire
/// on every refresh.
@collection
class PriceAlert {
  Id id = Isar.autoIncrement;

  late String symbol;

  String name = '';

  /// `above` or `below`, stored as text so the enum can be reordered safely.
  late String direction;

  late double threshold;

  late String currency;

  bool enabled = true;

  /// Which side of the threshold the price was last seen on. `null` until the
  /// first check has run.
  bool? lastAbove;

  DateTime? triggeredAt;

  late DateTime createdAt;

  late DateTime updatedAt;

  @ignore
  AlertDirection get side => AlertDirection.fromStorage(direction);

  /// One-line summary, e.g. `AAPL rises above $250.00`.
  String summary({bool roundTwoDp = true}) {
    final level = roundTwoDp
        ? threshold.toStringAsFixed(2)
        : threshold.toString();
    return '$symbol ${side.phrase} $level';
  }

  /// Decides whether [price] should fire this alert.
  AlertCheck check(double price) {
    if (!price.isFinite) {
      return const AlertCheck(shouldNotify: false, isAbove: false);
    }
    final isAbove = price > threshold;
    final previous = lastAbove;
    if (!enabled || previous == null) {
      return AlertCheck(shouldNotify: false, isAbove: isAbove);
    }
    final crossed = side == AlertDirection.above
        ? (!previous && isAbove)
        : (previous && !isAbove);
    return AlertCheck(shouldNotify: crossed, isAbove: isAbove);
  }
}

/// The editable fields of an alert, produced by the editor sheet.
class PriceAlertDraft {
  const PriceAlertDraft({
    required this.symbol,
    required this.name,
    required this.direction,
    required this.threshold,
    required this.currency,
  });

  final String symbol;
  final String name;
  final AlertDirection direction;
  final double threshold;
  final String currency;
}

/// One rule that crossed its level, with the price that did it.
class FiredAlert {
  const FiredAlert({required this.alert, required this.price});

  final PriceAlert alert;
  final double price;
}

/// The result of running every rule against the latest quotes.
class AlertPass {
  const AlertPass({required this.alerts, required this.fired});

  /// Every rule, with `lastAbove` updated. Persist these.
  final List<PriceAlert> alerts;

  final List<FiredAlert> fired;
}

/// Applies the crossing rule to every alert.
///
/// This is the single implementation of "what counts as a crossing": the app
/// calls it while it is running, and the Android background job calls the very
/// same function from a headless engine. Two implementations of this rule would
/// eventually disagree, and the symptom would be duplicate or missing alerts.
AlertPass evaluateAlertRules({
  required List<PriceAlert> alerts,
  required Map<String, Quote> quotes,
}) {
  final fired = <FiredAlert>[];
  for (final alert in alerts) {
    final quote = quotes[alert.symbol];
    if (quote == null) continue;
    final check = alert.check(quote.lastPrice);
    if (!check.shouldNotify && check.isAbove == alert.lastAbove) continue;
    alert.lastAbove = check.isAbove;
    if (check.shouldNotify) {
      alert.triggeredAt = DateTime.now();
      fired.add(FiredAlert(alert: alert, price: quote.lastPrice));
    }
  }
  return AlertPass(alerts: alerts, fired: fired);
}
