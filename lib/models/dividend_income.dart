import 'dividend.dart';
import 'position_ledger.dart';
import 'portfolio_math.dart';

/// Dividend cash attributed to one position over the trailing twelve months.
class DividendIncome {
  const DividendIncome({
    required this.symbol,
    required this.currency,
    required this.trailingAmount,
    required this.paymentCount,
  });

  final String symbol;
  final String currency;

  /// Cash received in the last twelve months. Estimated by applying each
  /// payment to the share count held *today* — see [DividendSummary] for why
  /// that is the honest ceiling of an average-cost position.
  final double trailingAmount;

  final int paymentCount;

  bool get isPaying => paymentCount > 0;
}

/// Dividend income across the portfolio, grouped by currency exactly the way
/// market value is: amounts in different currencies are never added together.
///
/// The estimate applies today's share count to every historical payment, so a
/// position that was bought, added to or trimmed during the year is
/// approximate. That limitation is stated in the UI rather than hidden.
class DividendSummary {
  const DividendSummary({
    required this.incomes,
    required this.trailingByCurrency,
    required this.costBasisByCurrency,
    this.estimatedCount = 0,
  });

  final List<DividendIncome> incomes;

  /// Trailing twelve-month cash per currency.
  final Map<String, double> trailingByCurrency;

  /// Cost basis per currency, so yield on cost can be derived without asking
  /// the positions again.
  final Map<String, double> costBasisByCurrency;

  /// Paying positions whose figures fall back to today's share count because
  /// no transaction ledger explains them.
  final int estimatedCount;

  static const empty = DividendSummary(
    incomes: [],
    trailingByCurrency: {},
    costBasisByCurrency: {},
  );

  /// Positions that paid at least once in the window, largest first.
  List<DividendIncome> get payers => [
        for (final income in incomes)
          if (income.isPaying) income,
      ];

  int get payingCount => payers.length;

  bool get hasAny => payingCount > 0;

  /// Cash in [currency] over the trailing twelve months.
  double trailingFor(String currency) => trailingByCurrency[currency] ?? 0;

  /// Trailing cash as a percentage of what the position cost. `null` when there
  /// is no cost basis to compare against.
  double? yieldOnCost(String currency) {
    final cost = costBasisByCurrency[currency] ?? 0;
    if (cost <= 0) return null;
    return trailingFor(currency) / cost * 100;
  }

  /// Builds the summary from priced positions and the payments fetched for
  /// them. Payments outside the trailing window are ignored.
  factory DividendSummary.from({
    required PortfolioSummary portfolio,
    required Map<String, List<DividendPayment>> payments,
    Map<String, PositionLedger> ledgers = const {},
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final windowStart = now.toUtc().subtract(const Duration(days: 365));
    final windowEnd = now.toUtc();

    final incomes = <DividendIncome>[];
    final trailing = <String, double>{};
    final costBasis = <String, double>{};
    var estimated = 0;

    for (final position in portfolio.positions) {
      final history = payments[position.symbol] ?? const <DividendPayment>[];
      final ledger = ledgers[position.symbol];
      var amount = 0.0;
      var count = 0;
      for (final payment in history) {
        final date = payment.date.toUtc();
        if (date.isBefore(windowStart) || date.isAfter(windowEnd)) continue;
        // With a ledger the payment is credited to the position as it stood on
        // that date; without one, today's share count is the best available
        // answer and the UI says so.
        final shares = ledger?.sharesOn(payment.date) ?? position.shares;
        if (shares <= 0) continue;
        amount += payment.amount * shares;
        count++;
      }
      final currency = position.currency;
      if (count > 0) {
        if (ledger == null) estimated++;
        trailing[currency] = (trailing[currency] ?? 0) + amount;
        costBasis[currency] = (costBasis[currency] ?? 0) + position.costBasis;
      }
      if (amount != 0 || count > 0) {
        incomes.add(
          DividendIncome(
            symbol: position.symbol,
            currency: currency,
            trailingAmount: amount,
            paymentCount: count,
          ),
        );
      }
    }

    incomes.sort((a, b) {
      final byAmount = b.trailingAmount.compareTo(a.trailingAmount);
      return byAmount != 0 ? byAmount : a.symbol.compareTo(b.symbol);
    });

    return DividendSummary(
      incomes: incomes,
      trailingByCurrency: trailing,
      costBasisByCurrency: costBasis,
      estimatedCount: estimated,
    );
  }
}
