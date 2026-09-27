/// A single executed buy or sell. Transactions are the only source of truth for
/// a position: quantities, average cost and realized P&L are all derived, never
/// stored, so edits and deletions always recompute consistently.
library;

enum TradeSide { buy, sell }

class Transaction {
  const Transaction({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.executedAt,
    this.fees = 0,
    this.note = '',
  });

  final String id;
  final String symbol;
  final TradeSide side;
  final double quantity;
  final double price;
  final DateTime executedAt;

  /// Commissions and exchange fees for this fill, in the instrument currency.
  /// Buys add them to the cost basis, sells subtract them from the proceeds.
  final double fees;
  final String note;

  /// Quantity × price, before fees.
  double get grossAmount => quantity * price;

  /// Signed cash impact: negative when buying, positive when selling.
  double get cashFlow => switch (side) {
        TradeSide.buy => -(grossAmount + fees),
        TradeSide.sell => grossAmount - fees,
      };

  bool get isBuy => side == TradeSide.buy;

  Transaction copyWith({
    String? symbol,
    TradeSide? side,
    double? quantity,
    double? price,
    DateTime? executedAt,
    double? fees,
    String? note,
  }) {
    return Transaction(
      id: id,
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      executedAt: executedAt ?? this.executedAt,
      fees: fees ?? this.fees,
      note: note ?? this.note,
    );
  }

  @override
  String toString() =>
      'Transaction($id, $symbol, ${side.name}, $quantity @ $price)';
}
