import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/position_ledger.dart';
import 'package:needhamcapital/models/portfolio_math.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/models/transaction.dart';

Transaction _trade({
  String symbol = 'AAPL',
  required TransactionKind kind,
  required double shares,
  required double price,
  double fee = 0,
  required DateTime on,
}) {
  return Transaction()
    ..symbol = symbol
    ..kind = kind.storageValue
    ..shares = shares
    ..pricePerShare = price
    ..fee = fee
    ..tradedAt = on
    ..currency = 'USD';
}

Holding _holding({
  String symbol = 'AAPL',
  double shares = 10,
  double costPerShare = 100,
}) {
  return Holding()
    ..symbol = symbol
    ..name = symbol
    ..shares = shares
    ..costPerShare = costPerShare
    ..currency = 'USD'
    ..createdAt = DateTime(2026, 1, 1)
    ..updatedAt = DateTime(2026, 1, 1);
}

Quote _quote(String symbol) => Quote(
      symbol: symbol,
      name: symbol,
      lastPrice: 120,
      change: 1,
      changePercent: 1,
    );

void main() {
  group('PositionLedger', () {
    test('a buy sets the share count and carries the fee into the average', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          fee: 5,
          on: DateTime(2026, 1, 10),
        ),
      ]);

      expect(ledger.shares, 10);
      expect(ledger.averageCost, closeTo(100.5, 1e-9));
      expect(ledger.costBasis, closeTo(1005, 1e-9));
      expect(ledger.hasRealized, isFalse);
      expect(ledger.lastTradedAt, DateTime(2026, 1, 10));
    });

    test('a sell realises P/L at the average and leaves the average alone', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          fee: 5,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          kind: TransactionKind.sell,
          shares: 4,
          price: 120,
          fee: 5,
          on: DateTime(2026, 2, 10),
        ),
      ]);

      expect(ledger.shares, 6);
      expect(ledger.averageCost, closeTo(100.5, 1e-9));
      final sale = ledger.sales.single;
      // 4 x 120 - 5 fee, against 4 x 100.50 of average cost.
      expect(sale.proceeds, closeTo(475, 1e-9));
      expect(sale.cost, closeTo(402, 1e-9));
      expect(sale.profit, closeTo(73, 1e-9));
      expect(ledger.realizedProfit, closeTo(73, 1e-9));
    });

    test('a second buy at a different price moves the average', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 200,
          on: DateTime(2026, 2, 10),
        ),
        _trade(
          kind: TransactionKind.sell,
          shares: 10,
          price: 180,
          on: DateTime(2026, 3, 10),
        ),
      ]);

      expect(ledger.shares, 10);
      expect(ledger.averageCost, closeTo(150, 1e-9));
      // Sold at 180 what cost 150 on average.
      expect(ledger.realizedProfit, closeTo(300, 1e-9));
    });

    test('orders transactions by date, not by the order they were entered', () {
      final late = _trade(
        kind: TransactionKind.sell,
        shares: 4,
        price: 120,
        on: DateTime(2026, 2, 10),
      );
      final early = _trade(
        kind: TransactionKind.buy,
        shares: 10,
        price: 100,
        on: DateTime(2026, 1, 10),
      );

      final ledger = PositionLedger.from('AAPL', [late, early]);

      // Selling before the buy would have been an oversell of 4 shares.
      expect(ledger.unmatchedShares, 0);
      expect(ledger.shares, 6);
      expect(ledger.realizedProfit, closeTo(80, 1e-9));
    });

    test('never sells shares the ledger has no record of', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 5,
          price: 100,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          kind: TransactionKind.sell,
          shares: 8,
          price: 110,
          on: DateTime(2026, 2, 10),
        ),
      ]);

      expect(ledger.shares, 0);
      expect(ledger.averageCost, 0);
      expect(ledger.isClosed, isTrue);
      // The excess is reported instead of being counted as a 3-share short.
      expect(ledger.unmatchedShares, 3);
      expect(ledger.realizedProfit, closeTo(50, 1e-9));
    });

    test('ignores transactions with no shares', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 0,
          price: 100,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          on: DateTime(2026, 2, 10),
        ),
      ]);

      expect(ledger.shares, 10);
      expect(ledger.transactionCount, 2);
    });

    test('allFrom groups by symbol', () {
      final ledgers = PositionLedger.allFrom([
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          symbol: 'MSFT',
          kind: TransactionKind.buy,
          shares: 2,
          price: 400,
          on: DateTime(2026, 1, 11),
        ),
      ]);

      expect(ledgers.keys, unorderedEquals(['AAPL', 'MSFT']));
      expect(ledgers['AAPL']!.shares, 10);
      expect(ledgers['MSFT']!.costBasis, closeTo(800, 1e-9));
    });

    test('reports how many shares were held on any given day', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          kind: TransactionKind.sell,
          shares: 4,
          price: 120,
          on: DateTime(2026, 2, 10),
        ),
      ]);

      expect(ledger.sharesOn(DateTime(2026, 1, 1)), 0);
      expect(ledger.sharesOn(DateTime(2026, 1, 10)), 10);
      expect(ledger.sharesOn(DateTime(2026, 2, 9)), 10);
      expect(ledger.sharesOn(DateTime(2026, 2, 10)), 6);
      expect(ledger.sharesOn(DateTime(2026, 12, 31)), 6);
    });
  });

  group('PortfolioSummary with ledgers', () {
    test('the ledger overrides the hand-entered position', () {
      final ledger = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 4,
          price: 50,
          on: DateTime(2026, 1, 10),
        ),
      ]);

      final summary = PortfolioSummary.from(
        [_holding(shares: 10, costPerShare: 100)],
        {'AAPL': _quote('AAPL')},
        ledgers: {'AAPL': ledger},
      );

      final position = summary.positions.single;
      expect(position.isFromLedger, isTrue);
      expect(position.shares, 4);
      expect(position.costPerShare, 50);
      // 4 shares at 120 against a 200 cost basis.
      expect(position.marketValue, 480);
      expect(position.profit, 280);
      expect(position.profitPercent, closeTo(140, 1e-9));
    });

    test('reports realised P/L per currency even with nothing left held', () {
      final closed = PositionLedger.from('AAPL', [
        _trade(
          kind: TransactionKind.buy,
          shares: 10,
          price: 100,
          on: DateTime(2026, 1, 10),
        ),
        _trade(
          kind: TransactionKind.sell,
          shares: 10,
          price: 130,
          on: DateTime(2026, 2, 10),
        ),
      ]);

      final summary = PortfolioSummary.from(
        [_holding()],
        {'AAPL': _quote('AAPL')},
        ledgers: {'AAPL': closed},
      );

      expect(summary.hasRealized, isTrue);
      expect(summary.realizedSalesCount, 1);
      expect(summary.realizedFor('USD'), closeTo(300, 1e-9));
      expect(summary.realizedFor('EUR'), 0);
      expect(summary.positions.single.isClosed, isTrue);
      // A closed position contributes nothing to the totals.
      expect(summary.primaryTotals!.marketValue, 0);
    });
  });
}
