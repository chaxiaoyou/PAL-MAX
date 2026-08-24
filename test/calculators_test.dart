import 'package:flutter_test/flutter_test.dart';
import 'package:pal_max/utils/calculators.dart';

void main() {
  group('Compound interest', () {
    test('yearly: 10000 principal, 10% rate, 1 year', () {
      final result = calcCompound(
        principal: 10000,
        contribution: 0,
        monthly: false,
        annualRatePct: 10,
        years: 1,
      );
      expect(result.total, closeTo(11000, 0.001));
      expect(result.totalInterest, closeTo(1000, 0.001));
      expect(result.totalReturnRate, closeTo(10, 0.001));
    });

    test('monthly contributions generate yearly rows', () {
      final result = calcCompound(
        principal: 1000,
        contribution: 100,
        monthly: true,
        annualRatePct: 12,
        years: 2,
      );
      expect(result.rows.length, 2);
      expect(result.rows.first.contributed, closeTo(1200, 0.001));
      expect(result.rows.last.endTotal, greaterThan(1000 + 2400));
    });
  });

  group('Risk / reward', () {
    test('long 1:2 risk-reward ratio', () {
      final result = calcRiskReward(
        isLong: true,
        futures: false,
        entry: 100,
        stop: 90,
        target: 120,
        qty: 10,
        multiplier: 1,
        marginPct: 0,
      );
      expect(result.ratio, closeTo(2, 0.001));
      expect(result.targetProfit, closeTo(200, 0.001));
      expect(result.expectedLoss, closeTo(100, 0.001));
    });

    test('short with futures multiplier', () {
      final result = calcRiskReward(
        isLong: false,
        futures: true,
        entry: 100,
        stop: 110,
        target: 80,
        qty: 3,
        multiplier: 10,
        marginPct: 10,
      );
      expect(result.ratio, closeTo(2, 0.001));
      expect(result.targetProfit, closeTo(600, 0.001));
      expect(result.marginRequired, closeTo(300, 0.001));
      expect(result.returnOnMargin, closeTo(200, 0.001));
    });
  });

  group('Position cost', () {
    test('average cost after adding', () {
      final result = calcPositionCost([
        PositionRecord(
            date: DateTime(2026, 1, 1), isBuy: true, price: 10, qty: 100),
        PositionRecord(
            date: DateTime(2026, 2, 1), isBuy: true, price: 20, qty: 100),
      ]);
      expect(result.totalAmount, closeTo(3000, 0.001));
      expect(result.totalQty, closeTo(200, 0.001));
      expect(result.avgCost, closeTo(15, 0.001));
    });

    test('reducing deducts at average cost', () {
      final result = calcPositionCost([
        PositionRecord(
            date: DateTime(2026, 1, 1), isBuy: true, price: 10, qty: 100),
        PositionRecord(
            date: DateTime(2026, 3, 1), isBuy: false, price: 20, qty: 40),
      ]);
      expect(result.totalQty, closeTo(60, 0.001));
      expect(result.totalAmount, closeTo(600, 0.001));
      expect(result.avgCost, closeTo(10, 0.001));
    });
  });

  group('Position size', () {
    test('derive quantity from max loss', () {
      final result = calcPositionSize(entry: 100, stop: 95, maxLoss: 500);
      expect(result.maxQty, closeTo(100, 0.001));
      expect(result.totalValue, closeTo(10000, 0.001));
      expect(result.movePct, closeTo(5, 0.001));
    });
  });

  group('Dividend reinvestment', () {
    test('yield and reinvested shares', () {
      final result =
          calcDividend(price: 10, dividendPerShare: 0.5, shares: 100);
      expect(result.yieldPct, closeTo(5, 0.001));
      expect(result.totalDividend, closeTo(50, 0.001));
      expect(result.extraShares, closeTo(5, 0.001));
      expect(result.totalShares, closeTo(105, 0.001));
    });
  });

  group('Profit & loss', () {
    test('long profit', () {
      final result = calcPnl(
        isLong: true,
        entry: 100,
        exit: 110,
        qty: 10,
        feePct: 0,
      );
      expect(result.amount, closeTo(100, 0.001));
      expect(result.returnPct, closeTo(10, 0.001));
    });

    test('short profit', () {
      final result = calcPnl(
        isLong: false,
        entry: 100,
        exit: 90,
        qty: 10,
        feePct: 0,
      );
      expect(result.amount, closeTo(100, 0.001));
    });
  });

  group('Target price', () {
    test('long target price', () {
      final result = calcTargetPrice(isLong: true, price: 100, ratePct: 20);
      expect(result.target, closeTo(120, 0.001));
      expect(result.change, closeTo(20, 0.001));
    });
  });

  group('Annual return', () {
    test('annualized compounding', () {
      final result =
          calcAnnualReturn(principal: 10000, target: 12100, years: 2);
      expect(result.totalReturnPct, closeTo(21, 0.001));
      expect(result.annualizedPct, closeTo(10, 0.001));
    });
  });

  group('Time to target', () {
    test('doubling takes about 10 years at 7.2%', () {
      final result =
          calcSavingsTime(principal: 10000, target: 20000, annualRatePct: 7.2);
      expect(result.years, closeTo(10, 0.3));
    });
  });

  group('ROI', () {
    test('return amount mode', () {
      final result = calcRoi(incomeMode: true, cost: 1000, amount: 200);
      expect(result.returnPct, closeTo(20, 0.001));
      expect(result.profit, closeTo(200, 0.001));
    });

    test('final value mode', () {
      final result = calcRoi(incomeMode: false, cost: 1000, amount: 1500);
      expect(result.returnPct, closeTo(50, 0.001));
    });
  });
}
