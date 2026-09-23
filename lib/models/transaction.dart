import 'package:isar_community/isar.dart';

part 'transaction.g.dart';

enum TransactionKind {
  buy('buy', 'Buy'),
  sell('sell', 'Sell');

  const TransactionKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static TransactionKind fromStorage(String? value) =>
      value == sell.storageValue ? sell : buy;
}

/// One trade. The ledger is the precise record of a position; a [Holding] is
/// the materialised "what do I hold now" view of it.
@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late String symbol;

  /// `buy` or `sell`. Stored as text rather than the enum's index so the file
  /// stays readable and reordering the enum cannot reinterpret old rows.
  late String kind;

  late double shares;

  /// Price per share, in [currency].
  late double pricePerShare;

  /// Commission and other costs, in [currency]. Defaults to zero.
  double fee = 0;

  late DateTime tradedAt;

  late String currency;

  /// Free text. `Opening balance` marks the entry created when a manually
  /// entered position is converted into a ledger.
  String note = '';

  /// The parsed [kind]. Not persisted — `kind` is the stored form, so the
  /// enum's declaration order can never reinterpret old rows.
  @ignore
  TransactionKind get type => TransactionKind.fromStorage(kind);
}

/// The editable fields of a trade, produced by the editor sheet.
class TransactionDraft {
  const TransactionDraft({
    required this.symbol,
    required this.kind,
    required this.shares,
    required this.pricePerShare,
    required this.fee,
    required this.tradedAt,
    required this.currency,
    this.note = '',
  });

  final String symbol;
  final TransactionKind kind;
  final double shares;
  final double pricePerShare;
  final double fee;
  final DateTime tradedAt;
  final String currency;
  final String note;
}
