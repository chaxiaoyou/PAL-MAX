import 'package:flutter_test/flutter_test.dart';
import 'package:pjza/domain/portfolio_math.dart';
import 'package:pjza/domain/position.dart';
import 'package:pjza/domain/transaction.dart';

Transaction buy(
  String id,
  double qty,
  double price, {
  double fees = 0,
  String symbol = 'WALMEX',
  DateTime? at,
}) {
  return Transaction(
    id: id,
    symbol: symbol,
    side: TradeSide.buy,
    quantity: qty,
    price: price,
    fees: fees,
    executedAt: at ?? DateTime(2026, 1, 1),
  );
}

Transaction sell(
  String id,
  double qty,
  double price, {
  double fees = 0,
  String symbol = 'WALMEX',
  DateTime? at,
}) {
  return Transaction(
    id: id,
    symbol: symbol,
    side: TradeSide.sell,
    quantity: qty,
    price: price,
    fees: fees,
    executedAt: at ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('buildLedger', () {
    test('a single buy capitalises fees into the cost basis', () {
      final ledger = buildLedger([buy('t1', 10, 100, fees: 50)]);
      final position = ledger.positionFor('WALMEX');

      expect(position.quantity, closeTo(10, 1e-9));
      expect(position.averageCost, closeTo(105, 1e-9));
      expect(position.costBasis, closeTo(1050, 1e-9));
      expect(position.realizedPnl, 0);
      expect(position.isOpen, isTrue);
    });

    test('subsequent buys move the weighted average', () {
      final ledger = buildLedger([
        buy('t1', 10, 100, fees: 50),
        buy('t2', 10, 120),
      ]);
      final position = ledger.positionFor('WALMEX');

      expect(position.quantity, closeTo(20, 1e-9));
      expect(position.averageCost, closeTo(112.5, 1e-9));
      expect(position.costBasis, closeTo(2250, 1e-9));
    });

    test('a partial sell books realized P&L and keeps the average cost', () {
      final ledger = buildLedger([
        buy('t1', 10, 100, fees: 50),
        buy('t2', 10, 120),
        sell('t3', 5, 130, fees: 10),
      ]);
      final position = ledger.positionFor('WALMEX');

      // Proceeds 640 − basis 562.50
      expect(position.realizedPnl, closeTo(77.5, 1e-9));
      expect(ledger.realizedPnl, closeTo(77.5, 1e-9));
      expect(position.quantity, closeTo(15, 1e-9));
      expect(position.averageCost, closeTo(112.5, 1e-9));
      expect(position.costBasis, closeTo(1687.5, 1e-9));
      expect(position.feesPaid, closeTo(60, 1e-9));
    });

    test('closing a position resets its basis but keeps realized P&L', () {
      final ledger = buildLedger([
        buy('t1', 10, 100),
        sell('t2', 10, 110),
      ]);
      final closed = ledger.positionFor('WALMEX');

      expect(closed.isClosed, isTrue);
      expect(closed.quantity, 0);
      expect(closed.averageCost, 0);
      expect(closed.realizedPnl, closeTo(100, 1e-9));

      // Re-opening must not inherit the old basis.
      final reopened = buildLedger([
        buy('t1', 10, 100),
        sell('t2', 10, 110),
        buy('t3', 4, 200),
      ]).positionFor('WALMEX');

      expect(reopened.quantity, closeTo(4, 1e-9));
      expect(reopened.averageCost, closeTo(200, 1e-9));
    });

    test('overselling closes the position and warns instead of going negative', () {
      final ledger = buildLedger([
        buy('t1', 10, 100),
        sell('t2', 15, 120),
      ]);
      final position = ledger.positionFor('WALMEX');

      expect(position.quantity, 0);
      expect(position.isClosed, isTrue);
      expect(ledger.warnings, hasLength(1));
      expect(ledger.warnings.single.kind, LedgerWarningKind.oversell);
      expect(ledger.warnings.single.symbol, 'WALMEX');
      expect(ledger.warnings.single.transactionId, 't2');
      expect(ledger.warnings.single.quantity, closeTo(5, 1e-9));
      // Only the 10 held units are booked as realized.
      expect(position.realizedPnl, closeTo(200, 1e-9));
    });

    test('transactions are replayed in execution order, not input order', () {
      final ledger = buildLedger([
        buy('late', 10, 200, at: DateTime(2026, 3, 1)),
        buy('early', 10, 100, at: DateTime(2026, 1, 1)),
      ]);

      expect(ledger.positionFor('WALMEX').averageCost, closeTo(150, 1e-9));
    });

    test('symbols keep first-traded order and closed ones stay listed', () {
      final ledger = buildLedger([
        buy('t1', 1, 10, symbol: 'FEMSA'),
        buy('t2', 1, 20, symbol: 'CEMEX'),
        sell('t3', 1, 15, symbol: 'FEMSA'),
      ]);

      expect(ledger.positions.keys.toList(), ['FEMSA', 'CEMEX']);
      expect(ledger.openPositions.map((p) => p.symbol).toList(), ['CEMEX']);
    });
  });

  group('valuePortfolio', () {
    LedgerResult ledgerFixture() => buildLedger([
          buy('t1', 10, 100, fees: 50, symbol: 'WALMEX'),
          buy('t2', 10, 120, symbol: 'WALMEX'),
          buy('t3', 5, 200, symbol: 'FEMSA'),
        ]);

    Map<String, PriceSnapshot> pricesFixture() => {
          'WALMEX': PriceSnapshot(
            symbol: 'WALMEX',
            price: 140,
            previousClose: 138,
            asOf: DateTime(2026, 2, 1),
          ),
          'FEMSA': PriceSnapshot(
            symbol: 'FEMSA',
            price: 190,
            previousClose: 195,
            asOf: DateTime(2026, 2, 1),
          ),
        };

    test('aggregates market value, cost basis and P&L', () {
      final valuation = valuePortfolio(
        ledger: ledgerFixture(),
        prices: pricesFixture(),
      );

      // WALMEX 20 × 140 = 2800, FEMSA 5 × 190 = 950
      expect(valuation.marketValue, closeTo(3750, 1e-9));
      expect(valuation.costBasis, closeTo(3250, 1e-9));
      expect(valuation.unrealizedPnl, closeTo(500, 1e-9));
      expect(valuation.unrealizedPct, closeTo(500 / 3250 * 100, 1e-9));
      expect(valuation.isPartial, isFalse);
    });

    test('a partial sell shrinks both the value and the basis', () {
      final ledger = buildLedger([
        buy('t1', 10, 100, fees: 50, symbol: 'WALMEX'),
        buy('t2', 10, 120, symbol: 'WALMEX'),
        sell('t3', 5, 130, fees: 10, symbol: 'WALMEX'),
      ]);

      final valuation = valuePortfolio(
        ledger: ledger,
        prices: {
          'WALMEX': PriceSnapshot(
            symbol: 'WALMEX',
            price: 140,
            previousClose: 138,
            asOf: DateTime(2026, 2, 1),
          ),
        },
      );

      expect(valuation.marketValue, closeTo(2100, 1e-9));
      expect(valuation.costBasis, closeTo(1687.5, 1e-9));
      expect(valuation.unrealizedPnl, closeTo(412.5, 1e-9));
      expect(valuation.realizedPnl, closeTo(77.5, 1e-9));
      expect(valuation.totalPnl, closeTo(490, 1e-9));
      expect(valuation.dayChangeValue, closeTo(30, 1e-9));
    });

    test('weights the allocation and orders it by value', () {
      final valuation = valuePortfolio(
        ledger: ledgerFixture(),
        prices: pricesFixture(),
      );

      expect(valuation.slices.first.symbol, 'WALMEX');
      expect(valuation.slices.first.weight, closeTo(2800 / 3750 * 100, 1e-9));
      expect(valuation.slices.last.weight, closeTo(950 / 3750 * 100, 1e-9));
      expect(
        valuation.slices.fold<double>(0, (sum, slice) => sum + slice.weight),
        closeTo(100, 1e-9),
      );
    });

    test('daily change only counts symbols that reported a previous close', () {
      final prices = pricesFixture();
      prices['FEMSA'] = PriceSnapshot(
        symbol: 'FEMSA',
        price: 190,
        asOf: DateTime(2026, 2, 1),
      );

      final valuation = valuePortfolio(ledger: ledgerFixture(), prices: prices);

      // WALMEX +2 × 20 = 40; FEMSA contributes nothing without a close.
      expect(valuation.dayChangeValue, closeTo(40, 1e-9));
    });

    test('unpriced holdings are reported instead of counted as zero', () {
      final prices = pricesFixture()..remove('FEMSA');
      final valuation = valuePortfolio(ledger: ledgerFixture(), prices: prices);

      expect(valuation.marketValue, closeTo(2800, 1e-9));
      expect(valuation.missingPrices, ['FEMSA']);
      expect(valuation.isPartial, isTrue);
    });

    test('cash is part of the portfolio value but not of unrealized P&L', () {
      final valuation = valuePortfolio(
        ledger: ledgerFixture(),
        prices: pricesFixture(),
        cash: 1000,
      );

      expect(valuation.marketValue, closeTo(4750, 1e-9));
      expect(valuation.unrealizedPnl, closeTo(500, 1e-9));
    });

    test('fx rates convert foreign holdings into the base currency', () {
      final ledger = buildLedger([buy('t1', 10, 100, symbol: 'AAPL')]);
      final valuation = valuePortfolio(
        ledger: ledger,
        prices: {
          'AAPL': PriceSnapshot(
            symbol: 'AAPL',
            price: 100,
            previousClose: 100,
            currency: 'USD',
            fxRate: 18.5,
            asOf: DateTime(2026, 2, 1),
          ),
        },
      );

      expect(valuation.marketValue, closeTo(18500, 1e-9));
      expect(valuation.costBasis, closeTo(18500, 1e-9));
      expect(valuation.unrealizedPnl, closeTo(0, 1e-9));
    });

    test('an empty ledger values to zero without dividing by zero', () {
      final valuation = valuePortfolio(
        ledger: LedgerResult.empty,
        prices: const {},
      );

      expect(valuation.isEmpty, isTrue);
      expect(valuation.unrealizedPct, 0);
      expect(valuation.slices, isEmpty);
    });
  });

  group('investedTimeline', () {
    test('accumulates buys and reduces on sells', () {
      final points = investedTimeline([
        buy('t1', 10, 100, fees: 50, at: DateTime(2026, 1, 1)),
        sell('t2', 5, 130, fees: 10, at: DateTime(2026, 2, 1)),
      ]);

      expect(points, hasLength(2));
      expect(points.first.invested, closeTo(1050, 1e-9));
      expect(points.last.invested, closeTo(410, 1e-9));
    });
  });
}
