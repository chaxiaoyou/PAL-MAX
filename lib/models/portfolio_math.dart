import 'position_ledger.dart';
import 'holding.dart';
import 'quote.dart';

/// Market value and P/L for a single position, derived from the latest quote.
///
/// A position without a quote is deliberately *not* priced at zero: market
/// value and P/L are reported as unavailable so a missing quote can never show
/// up as a real loss.
class HoldingPerformance {
  const HoldingPerformance({
    required this.holding,
    required this.quote,
    this.ledger,
  });

  final Holding holding;
  final Quote? quote;

  /// When a symbol has transactions, they are what the position actually is:
  /// the hand-entered share count and average cost are only the fallback for
  /// positions that were never put on a ledger.
  final PositionLedger? ledger;

  bool get hasQuote => quote != null;

  bool get isFromLedger => ledger != null;

  /// Everything was sold: the row is kept so the realised P/L is still
  /// reachable, but it no longer holds anything.
  bool get isClosed => ledger != null && ledger!.isClosed;

  String get symbol => holding.symbol;
  String get name => holding.name;
  double get shares => ledger?.shares ?? holding.shares;
  double get costPerShare => ledger?.averageCost ?? holding.costPerShare;

  /// Currency reported by the live quote, falling back to the stored one.
  String get currency => quote?.currency ?? holding.currency;

  double get price => quote?.lastPrice ?? 0;
  // These read [shares] and [costPerShare], not the stored fields, so a
  // position on a ledger is priced from the ledger.
  double get costBasis => shares * costPerShare;
  double get marketValue => hasQuote ? shares * price : 0;
  double get profit => marketValue - costBasis;

  /// Return on cost. `null` when there is no cost basis to compare against.
  double? get profitPercent {
    if (!hasQuote || costBasis <= 0) return null;
    return profit / costBasis * 100;
  }

  /// Today's P/L for the position.
  double get dayChange => hasQuote ? shares * quote!.change : 0;

  /// Market value at yesterday's close, used to weight the day's percentage.
  double get previousValue => hasQuote ? shares * (price - quote!.change) : 0;

  /// One position, re-priced against the latest quote.
  HoldingPerformance withQuote(Quote? quote) =>
      HoldingPerformance(holding: holding, quote: quote, ledger: ledger);
}

/// Totals for a single currency. Positions in different currencies are never
/// added together — there is no FX rate anywhere in this model.
class PortfolioTotals {
  const PortfolioTotals({
    required this.currency,
    required this.marketValue,
    required this.costBasis,
    required this.previousValue,
    required this.dayChange,
    required this.positionCount,
  });

  final String currency;
  final double marketValue;
  final double costBasis;
  final double previousValue;
  final double dayChange;
  final int positionCount;

  double get profit => marketValue - costBasis;

  double? get profitPercent =>
      costBasis > 0 ? profit / costBasis * 100 : null;

  double? get dayChangePercent =>
      previousValue > 0 ? dayChange / previousValue * 100 : null;
}

/// Portfolio-wide view: every position plus totals grouped by currency.
class PortfolioSummary {
  const PortfolioSummary({
    required this.positions,
    required this.totalsByCurrency,
    required this.unpricedCount,
    this.realizedByCurrency = const {},
    this.realizedSalesCount = 0,
  });

  final List<HoldingPerformance> positions;
  final Map<String, PortfolioTotals> totalsByCurrency;

  /// Positions that could not be priced because no quote was available.
  final int unpricedCount;

  /// Money actually banked by selling, per currency. Independent of the
  /// current market value, so it is reported even for closed positions.
  final Map<String, double> realizedByCurrency;

  final int realizedSalesCount;

  static const empty = PortfolioSummary(
    positions: [],
    totalsByCurrency: {},
    unpricedCount: 0,
    realizedByCurrency: {},
    realizedSalesCount: 0,
  );

  int get positionCount => positions.length;

  /// Currencies ordered by market value, largest first. The first entry is the
  /// one the headline total is shown in.
  List<String> get orderedCurrencies {
    final codes = totalsByCurrency.keys.toList()
      ..sort(
        (a, b) => totalsByCurrency[b]!
            .marketValue
            .compareTo(totalsByCurrency[a]!.marketValue),
      );
    return codes;
  }

  String? get primaryCurrency =>
      orderedCurrencies.isEmpty ? null : orderedCurrencies.first;

  PortfolioTotals? get primaryTotals =>
      primaryCurrency == null ? null : totalsByCurrency[primaryCurrency!];

  bool get hasMultipleCurrencies => totalsByCurrency.length > 1;

  bool get hasRealized => realizedSalesCount > 0;

  double realizedFor(String currency) => realizedByCurrency[currency] ?? 0;

  /// Builds the summary from stored positions and the quotes fetched for them.
  /// Positions are ordered by market value, largest first, with unpriced ones
  /// last.
  factory PortfolioSummary.from(
    List<Holding> holdings,
    Map<String, Quote> quotes, {
    Map<String, PositionLedger> ledgers = const {},
  }) {
    final positions = [
      for (final holding in holdings)
        HoldingPerformance(
          holding: holding,
          quote: quotes[holding.symbol],
          ledger: ledgers[holding.symbol],
        ),
    ];

    final totals = <String, PortfolioTotals>{};
    final realized = <String, double>{};
    var salesCount = 0;
    var unpriced = 0;
    for (final position in positions) {
      // Realised P/L needs no quote, so it is collected before the position is
      // checked for pricing.
      final sales = position.ledger?.sales ?? const <RealizedSale>[];
      if (sales.isNotEmpty) {
        final currency = position.currency;
        realized[currency] =
            (realized[currency] ?? 0) + position.ledger!.realizedProfit;
        salesCount += sales.length;
      }
      if (!position.hasQuote) {
        unpriced++;
        continue;
      }
      final currency = position.currency;
      final current = totals[currency];
      totals[currency] = PortfolioTotals(
        currency: currency,
        marketValue: (current?.marketValue ?? 0) + position.marketValue,
        costBasis: (current?.costBasis ?? 0) + position.costBasis,
        previousValue: (current?.previousValue ?? 0) + position.previousValue,
        dayChange: (current?.dayChange ?? 0) + position.dayChange,
        positionCount: (current?.positionCount ?? 0) + 1,
      );
    }

    positions.sort((a, b) {
      final byValue = b.marketValue.compareTo(a.marketValue);
      return byValue != 0 ? byValue : a.symbol.compareTo(b.symbol);
    });

    return PortfolioSummary(
      positions: positions,
      totalsByCurrency: totals,
      unpricedCount: unpriced,
      realizedByCurrency: realized,
      realizedSalesCount: salesCount,
    );
  }
}
