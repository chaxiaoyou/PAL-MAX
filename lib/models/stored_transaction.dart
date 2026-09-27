import 'package:isar_community/isar.dart';

import '../domain/transaction.dart';

part 'stored_transaction.g.dart';

/// Persistence row for a portfolio transaction.
///
/// Separate from the domain [Transaction] on purpose: the domain object is what
/// the accounting logic reasons about, this one is what survives on disk. The
/// mapping is explicit so a schema change can never silently alter tax-relevant
/// numbers.
@collection
class StoredTransaction {
  Id id = Isar.autoIncrement;

  /// Stable identifier owned by the caller, distinct from Isar's own [id].
  ///
  /// Not indexed: a unique index makes the Isar generator emit APIs it still
  /// marks experimental, and at portfolio scale (hundreds of rows) the store
  /// can enforce uniqueness itself. `IsarPortfolioStore` looks the row up by
  /// `uid` before writing, which is covered by a test.
  late String uid;

  late String symbol;

  /// Stored as a code, not the enum ordinal: reordering [TradeSide] must never
  /// reinterpret rows that are already on disk.
  late String sideCode;

  late double quantity;
  late double price;
  late double fees;
  late DateTime executedAt;
  late String note;

  Transaction toDomain() => Transaction(
        id: uid,
        symbol: symbol,
        side: tradeSideFromCode(sideCode),
        quantity: quantity,
        price: price,
        fees: fees,
        executedAt: executedAt,
        note: note,
      );

  static StoredTransaction fromDomain(Transaction transaction) {
    return StoredTransaction()
      ..uid = transaction.id
      ..symbol = transaction.symbol
      ..sideCode = tradeSideCode(transaction.side)
      ..quantity = transaction.quantity
      ..price = transaction.price
      ..fees = transaction.fees
      ..executedAt = transaction.executedAt
      ..note = transaction.note;
  }
}

String tradeSideCode(TradeSide side) => switch (side) {
      TradeSide.buy => 'buy',
      TradeSide.sell => 'sell',
    };

TradeSide tradeSideFromCode(String code) =>
    code == 'sell' ? TradeSide.sell : TradeSide.buy;
