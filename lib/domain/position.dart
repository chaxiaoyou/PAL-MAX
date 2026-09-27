/// Derived state for one symbol: everything the UI needs about a holding, with
/// no reliance on stored aggregates.
class Position {
  const Position({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
    this.feesPaid = 0,
    this.realizedPnl = 0,
  });

  const Position.flat(this.symbol)
      : quantity = 0,
        averageCost = 0,
        feesPaid = 0,
        realizedPnl = 0;

  final String symbol;
  final double quantity;

  /// Moving weighted average cost per unit, fees included.
  final double averageCost;

  /// Lifetime fees paid on this symbol.
  final double feesPaid;

  /// Profit already booked by sells, net of the fees on those sells.
  final double realizedPnl;

  static const double _epsilon = 1e-9;

  bool get isOpen => quantity > _epsilon;
  bool get isClosed => !isOpen;

  /// Book value of the remaining units.
  double get costBasis => quantity * averageCost;

  Position copyWith({
    double? quantity,
    double? averageCost,
    double? feesPaid,
    double? realizedPnl,
  }) {
    return Position(
      symbol: symbol,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
      feesPaid: feesPaid ?? this.feesPaid,
      realizedPnl: realizedPnl ?? this.realizedPnl,
    );
  }

  @override
  String toString() =>
      'Position($symbol, qty: $quantity, avg: $averageCost, '
      'realized: $realizedPnl)';
}

/// Latest known price for a symbol plus what the UI needs to value it.
class PriceSnapshot {
  const PriceSnapshot({
    required this.symbol,
    required this.price,
    required this.asOf,
    this.previousClose = 0,
    this.currency = 'MXN',
    this.fxRate = 1,
  });

  final String symbol;
  final double price;
  final DateTime asOf;

  /// Previous session close, used for the daily change column. Zero means the
  /// provider did not report one and the day change is shown as unavailable.
  final double previousClose;
  final String currency;

  /// Multiplier converting [currency] into the portfolio's base currency.
  /// Defaults to 1 so single-currency portfolios need no wiring.
  final double fxRate;

  bool get hasPreviousClose => previousClose > 0;

  double get dayChange => hasPreviousClose ? price - previousClose : 0;

  double get dayChangePercent =>
      hasPreviousClose ? (price - previousClose) / previousClose * 100 : 0;

  PriceSnapshot copyWith({double? price, double? previousClose, double? fxRate}) {
    return PriceSnapshot(
      symbol: symbol,
      price: price ?? this.price,
      asOf: asOf,
      previousClose: previousClose ?? this.previousClose,
      currency: currency,
      fxRate: fxRate ?? this.fxRate,
    );
  }
}

/// One row of the allocation breakdown.
class AllocationSlice {
  const AllocationSlice({
    required this.symbol,
    required this.marketValue,
    required this.weight,
  });

  final String symbol;
  final double marketValue;

  /// Share of the portfolio's market value, 0–100.
  final double weight;
}

/// Everything the dashboard needs, computed in one pass.
class PortfolioValuation {
  const PortfolioValuation({
    required this.marketValue,
    required this.costBasis,
    required this.unrealizedPnl,
    required this.dayChangeValue,
    required this.realizedPnl,
    required this.slices,
    required this.missingPrices,
  });

  static const PortfolioValuation empty = PortfolioValuation(
    marketValue: 0,
    costBasis: 0,
    unrealizedPnl: 0,
    dayChangeValue: 0,
    realizedPnl: 0,
    slices: [],
    missingPrices: [],
  );

  final double marketValue;
  final double costBasis;
  final double unrealizedPnl;

  /// Daily change across open positions, excluding symbols without a previous
  /// close so the number never silently reads as zero.
  final double dayChangeValue;

  final double realizedPnl;
  final List<AllocationSlice> slices;

  /// Symbols held but not priced in this valuation — the UI should say so
  /// instead of under-reporting the total.
  final List<String> missingPrices;

  double get totalPnl => unrealizedPnl + realizedPnl;

  double get unrealizedPct =>
      costBasis.abs() < 1e-9 ? 0 : unrealizedPnl / costBasis * 100;

  bool get isEmpty => marketValue.abs() < 1e-9 && costBasis.abs() < 1e-9;

  /// True when at least one open position could not be priced, which makes the
  /// displayed totals partial.
  bool get isPartial => missingPrices.isNotEmpty;
}

enum LedgerWarningKind { oversell }

/// A structurally valid but suspicious transaction, surfaced to the user rather
/// than silently swallowed.
class LedgerWarning {
  const LedgerWarning({
    required this.kind,
    required this.symbol,
    required this.transactionId,
    required this.quantity,
  });

  final LedgerWarningKind kind;
  final String symbol;
  final String transactionId;

  /// How many units the sell exceeded the holding by.
  final double quantity;
}

/// Result of replaying transactions: derived positions plus anything odd.
class LedgerResult {
  const LedgerResult({
    required this.positions,
    required this.realizedPnl,
    required this.warnings,
  });

  static const LedgerResult empty = LedgerResult(
    positions: {},
    realizedPnl: 0,
    warnings: [],
  );

  final Map<String, Position> positions;
  final double realizedPnl;
  final List<LedgerWarning> warnings;

  Iterable<Position> get openPositions =>
      positions.values.where((position) => position.isOpen);

  Position positionFor(String symbol) =>
      positions[symbol] ?? Position.flat(symbol);
}
