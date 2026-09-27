import 'package:isar_community/isar.dart';

import '../domain/alert.dart';

part 'stored_alert.g.dart';

/// Persistence row for a price alert rule.
@collection
class StoredAlert {
  Id id = Isar.autoIncrement;

  /// See [StoredTransaction.uid] for why this is not indexed.
  late String uid;

  late String symbol;

  /// Stable code rather than the enum ordinal, same reasoning as
  /// [StoredTransaction.sideCode].
  late String kindCode;

  late double threshold;
  late DateTime createdAt;

  /// Null until the rule fires; persisted so a restart does not re-notify a
  /// rule that already fired.
  DateTime? triggeredAt;

  late bool enabled;
  late String note;

  Alert toDomain() => Alert(
        id: uid,
        symbol: symbol,
        kind: alertKindFromCode(kindCode),
        threshold: threshold,
        createdAt: createdAt,
        enabled: enabled,
        triggeredAt: triggeredAt,
        note: note,
      );

  static StoredAlert fromDomain(Alert alert) {
    return StoredAlert()
      ..uid = alert.id
      ..symbol = alert.symbol
      ..kindCode = alertKindCode(alert.kind)
      ..threshold = alert.threshold
      ..createdAt = alert.createdAt
      ..triggeredAt = alert.triggeredAt
      ..enabled = alert.enabled
      ..note = alert.note;
  }
}

String alertKindCode(AlertKind kind) => switch (kind) {
      AlertKind.priceAbove => 'priceAbove',
      AlertKind.priceBelow => 'priceBelow',
      AlertKind.percentChangeAbove => 'percentChangeAbove',
      AlertKind.percentChangeBelow => 'percentChangeBelow',
    };

AlertKind alertKindFromCode(String code) => switch (code) {
      'priceBelow' => AlertKind.priceBelow,
      'percentChangeAbove' => AlertKind.percentChangeAbove,
      'percentChangeBelow' => AlertKind.percentChangeBelow,
      _ => AlertKind.priceAbove,
    };
