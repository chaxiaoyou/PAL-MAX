import 'dart:math' as math;

import 'position.dart';
import 'transaction.dart';

/// Pure portfolio math: transactions in, positions and valuation out.
///
/// Nothing here touches storage or the network, so the accounting rules are
/// unit-testable in isolation — which matters, because a wrong average cost is
/// the kind of bug users notice immediately and never forgive.
const double _epsilon = 1e-9;

/// Replays [transactions] in execution order using the moving weighted-average
/// cost method, the standard for retail portfolios and the one Mexican brokers
/// report against for ISR purposes.
///
/// Fees on a buy are capitalised into the cost basis; fees on a sell reduce the
/// proceeds. The result is portfolio-wide realized P&L plus one derived
/// position per symbol (closed positions included, so their realized P&L stays
/// visible).
LedgerResult buildLedger(Iterable<Transaction> transactions) {
  final ordered = transactions.toList()
    ..sort((a, b) => a.executedAt.compareTo(b.executedAt));

  // LinkedHashMap keeps symbols in first-traded order, which is how the UI
  // lists them before the user chooses a sort.
  final positions = <String, Position>{};
  final warnings = <LedgerWarning>[];
  var realizedTotal = 0.0;

  for (final tx in ordered) {
    final current = positions[tx.symbol] ?? Position.flat(tx.symbol);

    if (tx.isBuy) {
      final newQty = current.quantity + tx.quantity;
      final newCost = current.costBasis + tx.grossAmount + tx.fees;
      positions[tx.symbol] = current.copyWith(
        quantity: newQty,
        averageCost: newQty <= _epsilon ? 0 : newCost / newQty,
        feesPaid: current.feesPaid + tx.fees,
      );
      continue;
    }

    // Sell. Overselling is a data-entry mistake, not a market event: close the
    // position at what is actually held and report the excess instead of
    // producing a negative quantity that poisons every later total.
    var soldQty = tx.quantity;
    if (soldQty > current.quantity + _epsilon) {
      warnings.add(
        LedgerWarning(
          kind: LedgerWarningKind.oversell,
          symbol: tx.symbol,
          transactionId: tx.id,
          quantity: soldQty - current.quantity,
        ),
      );
      soldQty = math.max(current.quantity, 0.0);
    }

    final feesThisFill = tx.fees;
    final proceeds = soldQty * tx.price - feesThisFill;
    final realized = proceeds - soldQty * current.averageCost;
    realizedTotal += realized;

    final newQty = math.max(current.quantity - soldQty, 0.0);
    positions[tx.symbol] = current.copyWith(
      quantity: newQty,
      // A closed position forgets its average cost; keeping it would make the
      // next buy inherit a stale basis.
      averageCost: newQty <= _epsilon ? 0 : current.averageCost,
      feesPaid: current.feesPaid + feesThisFill,
      realizedPnl: current.realizedPnl + realized,
    );
  }

  return LedgerResult(
    positions: positions,
    realizedPnl: realizedTotal,
    warnings: warnings,
  );
}

/// Values the open positions in a ledger against the latest known prices.
///
/// Symbols without a snapshot are reported in [PortfolioValuation.missingPrices]
/// rather than counted as zero — a partial total that says so is far less
/// dangerous than one that looks complete. Same for the daily change: symbols
/// without a previous close contribute nothing to it.
PortfolioValuation valuePortfolio({
  required LedgerResult ledger,
  required Map<String, PriceSnapshot> prices,
  double cash = 0,
}) {
  var marketValue = cash;
  var costBasis = 0.0;
  var dayChangeValue = 0.0;
  final missing = <String>[];
  final rows = <({String symbol, double value})>[];

  for (final position in ledger.openPositions) {
    final snapshot = prices[position.symbol];
    if (snapshot == null || !snapshot.price.isFinite) {
      missing.add(position.symbol);
      continue;
    }
    final fx = snapshot.fxRate;
    final value = position.quantity * snapshot.price * fx;
    marketValue += value;
    costBasis += position.costBasis * fx;
    if (snapshot.hasPreviousClose) {
      dayChangeValue += position.quantity * snapshot.dayChange * fx;
    }
    rows.add((symbol: position.symbol, value: value));
  }

  final slices = [
    for (final row in rows)
      AllocationSlice(
        symbol: row.symbol,
        marketValue: row.value,
        weight: marketValue.abs() < _epsilon ? 0 : row.value / marketValue * 100,
      ),
  ]..sort((a, b) => b.marketValue.compareTo(a.marketValue));

  return PortfolioValuation(
    marketValue: marketValue,
    costBasis: costBasis,
    unrealizedPnl: marketValue - cash - costBasis,
    dayChangeValue: dayChangeValue,
    realizedPnl: ledger.realizedPnl,
    slices: slices,
    missingPrices: missing,
  );
}

/// Cumulative net cash invested per symbol over time, used by the "aportado"
/// line on the portfolio chart. Sells reduce the line, which is why it is not
/// simply a running sum of buys.
List<({DateTime date, double invested})> investedTimeline(
  Iterable<Transaction> transactions,
) {
  final ordered = transactions.toList()
    ..sort((a, b) => a.executedAt.compareTo(b.executedAt));

  final points = <({DateTime date, double invested})>[];
  var running = 0.0;
  for (final tx in ordered) {
    running -= tx.cashFlow;
    points.add((date: tx.executedAt, invested: running));
  }
  return points;
}
