import 'transaction.dart';

/// One sale, with the P/L it realised against the average cost at that moment.
class RealizedSale {
  const RealizedSale({
    required this.date,
    required this.shares,
    required this.proceeds,
    required this.cost,
  });

  final DateTime date;
  final double shares;

  /// Cash received, net of the fee.
  final double proceeds;

  /// Average cost of the shares that were sold.
  final double cost;

  double get profit => proceeds - cost;
}

/// How many shares the ledger held from [date] onwards. Dividends are
/// attributed with this, so a payment is credited to the position as it
/// actually stood on the ex-dividend date rather than to today's share count.
class SharePoint {
  const SharePoint({required this.date, required this.shares});

  final DateTime date;
  final double shares;
}

/// What a symbol's transactions add up to.
///
/// Average-cost method: a buy raises the average, and a sell realises P/L at the
/// average in force at that moment and leaves the average unchanged. FIFO or
/// per-lot tracking would need lot records, and would give different realised
/// numbers for the same trades — so this is a decision, not an accident.
class PositionLedger {
  const PositionLedger({
    required this.symbol,
    required this.shares,
    required this.averageCost,
    required this.sales,
    required this.transactionCount,
    required this.unmatchedShares,
    required this.lastTradedAt,
    this.timeline = const [],
  });

  final String symbol;

  /// Shares held now.
  final double shares;

  /// Average cost per share of the shares still held; zero once the position is
  /// closed.
  final double averageCost;

  final List<RealizedSale> sales;
  final int transactionCount;

  /// Shares sold that the ledger had no record of owning, e.g. a sell recorded
  /// against a position entered by hand. Surfaced rather than swallowed.
  final double unmatchedShares;

  final DateTime? lastTradedAt;

  /// Share count after every trade, oldest first.
  final List<SharePoint> timeline;

  double get costBasis => shares * averageCost;

  double get realizedProfit {
    var total = 0.0;
    for (final sale in sales) {
      total += sale.profit;
    }
    return total;
  }

  bool get hasRealized => sales.isNotEmpty;

  bool get isClosed => shares <= 0;

  /// Shares held on [date], calendar-day precision. Zero before the first buy.
  double sharesOn(DateTime date) {
    final day = _calendarDay(date);
    var held = 0.0;
    for (final point in timeline) {
      if (_calendarDay(point.date).isAfter(day)) break;
      held = point.shares;
    }
    return held;
  }

  /// Local calendar day, so a trade timestamped at 09:00 and a payment at
  /// 00:00 UTC are compared as the days the user sees, not as instants.
  static DateTime _calendarDay(DateTime value) {
    final local = value.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Builds the ledger for [symbol] from its transactions, oldest first.
  factory PositionLedger.from(String symbol, List<Transaction> transactions) {
    final ordered = [...transactions]..sort((a, b) {
        final byDate = a.tradedAt.compareTo(b.tradedAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    var shares = 0.0;
    var costPool = 0.0;
    var unmatched = 0.0;
    final sales = <RealizedSale>[];
    final timeline = <SharePoint>[];

    for (final transaction in ordered) {
      final traded = transaction.shares;
      if (!traded.isFinite || traded <= 0) continue;
      if (transaction.type == TransactionKind.buy) {
        shares += traded;
        costPool += traded * transaction.pricePerShare + transaction.fee;
        timeline.add(
          SharePoint(date: transaction.tradedAt, shares: shares),
        );
        continue;
      }

      // A sell can never take out more than the ledger holds. The excess is
      // counted so the UI can say the ledger is incomplete instead of quietly
      // producing nonsense.
      final sold = traded <= shares ? traded : shares;
      unmatched += traded - sold;
      final average = shares > 0 ? costPool / shares : 0.0;
      final cost = sold * average;
      final proceeds = sold * transaction.pricePerShare - transaction.fee;
      sales.add(
        RealizedSale(
          date: transaction.tradedAt,
          shares: sold,
          proceeds: proceeds,
          cost: cost,
        ),
      );
      shares -= sold;
      costPool -= cost;
      if (shares <= 0) {
        shares = 0;
        costPool = 0;
      }
      timeline.add(SharePoint(date: transaction.tradedAt, shares: shares));
    }

    return PositionLedger(
      symbol: symbol,
      shares: shares,
      averageCost: shares > 0 ? costPool / shares : 0,
      sales: sales,
      transactionCount: ordered.length,
      unmatchedShares: unmatched,
      lastTradedAt: ordered.isEmpty ? null : ordered.last.tradedAt,
      timeline: timeline,
    );
  }

  /// Ledgers for every symbol that has transactions.
  static Map<String, PositionLedger> allFrom(List<Transaction> transactions) {
    final bySymbol = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      bySymbol.putIfAbsent(transaction.symbol, () => []).add(transaction);
    }
    return {
      for (final entry in bySymbol.entries)
        entry.key: PositionLedger.from(entry.key, entry.value),
    };
  }
}
