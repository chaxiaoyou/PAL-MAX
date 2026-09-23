import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/portfolio_math.dart';
import 'package:needhamcapital/models/quote.dart';

Holding holding({
  required String symbol,
  double shares = 10,
  double costPerShare = 100,
  String currency = 'USD',
}) {
  return Holding()
    ..symbol = symbol
    ..name = symbol
    ..shares = shares
    ..costPerShare = costPerShare
    ..currency = currency
    ..createdAt = DateTime(2026, 1, 1)
    ..updatedAt = DateTime(2026, 1, 1);
}

Quote quote({
  required String symbol,
  double price = 120,
  double change = 2,
  double changePercent = 1.7,
  String currency = 'USD',
}) {
  return Quote(
    symbol: symbol,
    name: symbol,
    lastPrice: price,
    change: change,
    changePercent: changePercent,
    currency: currency,
  );
}

void main() {
  group('HoldingPerformance', () {
    test('computes market value, profit and percent against cost basis', () {
      final position = HoldingPerformance(
        holding: holding(symbol: 'AAPL', shares: 10, costPerShare: 100),
        quote: quote(symbol: 'AAPL', price: 120, change: 2),
      );

      expect(position.costBasis, 1000);
      expect(position.marketValue, 1200);
      expect(position.profit, 200);
      expect(position.profitPercent, closeTo(20, 1e-9));
      expect(position.dayChange, 20);
    });

    test('reports a loss as negative profit', () {
      final position = HoldingPerformance(
        holding: holding(symbol: 'AAPL', shares: 4, costPerShare: 50),
        quote: quote(symbol: 'AAPL', price: 40, change: -1),
      );

      expect(position.profit, -40);
      expect(position.profitPercent, closeTo(-20, 1e-9));
      expect(position.dayChange, -4);
    });

    test('leaves a position without a quote unpriced instead of worth zero', () {
      final position = HoldingPerformance(
        holding: holding(symbol: 'ZZZZ', shares: 10, costPerShare: 100),
        quote: null,
      );

      expect(position.hasQuote, isFalse);
      // Cost basis is still known; value and P/L are not.
      expect(position.costBasis, 1000);
      expect(position.marketValue, 0);
      expect(position.profitPercent, isNull);
      expect(position.dayChange, 0);
      expect(position.currency, 'USD');
    });

    test('has no percent return when there is no cost basis', () {
      final position = HoldingPerformance(
        holding: holding(symbol: 'GIFT', shares: 5, costPerShare: 0),
        quote: quote(symbol: 'GIFT', price: 30),
      );

      expect(position.profit, 150);
      expect(position.profitPercent, isNull);
    });
  });

  group('PortfolioSummary', () {
    test('totals positions in the same currency', () {
      final summary = PortfolioSummary.from(
        [
          holding(symbol: 'AAPL', shares: 10, costPerShare: 100),
          holding(symbol: 'MSFT', shares: 5, costPerShare: 200),
        ],
        {
          'AAPL': quote(symbol: 'AAPL', price: 120, change: 2),
          'MSFT': quote(symbol: 'MSFT', price: 180, change: -3),
        },
      );

      final totals = summary.primaryTotals!;
      expect(summary.primaryCurrency, 'USD');
      expect(totals.marketValue, 10 * 120 + 5 * 180);
      expect(totals.costBasis, 10 * 100 + 5 * 200);
      expect(totals.profit, 1200 + 900 - 2000);
      expect(totals.dayChange, 10 * 2 + 5 * -3);
      expect(totals.positionCount, 2);
      expect(summary.unpricedCount, 0);
      expect(summary.hasMultipleCurrencies, isFalse);
    });

    test('never adds different currencies together', () {
      final summary = PortfolioSummary.from(
        [
          holding(symbol: 'AAPL', shares: 10, costPerShare: 100),
          holding(
            symbol: 'AIR.PA',
            shares: 2,
            costPerShare: 150,
            currency: 'EUR',
          ),
        ],
        {
          'AAPL': quote(symbol: 'AAPL', price: 120),
          'AIR.PA': quote(
            symbol: 'AIR.PA',
            price: 180,
            currency: 'EUR',
          ),
        },
      );

      expect(summary.hasMultipleCurrencies, isTrue);
      // Largest market value leads: 1200 USD beats 360 EUR.
      expect(summary.primaryCurrency, 'USD');
      expect(summary.orderedCurrencies, ['USD', 'EUR']);
      expect(summary.totalsByCurrency['USD']!.marketValue, 1200);
      expect(summary.totalsByCurrency['EUR']!.marketValue, 360);
    });

    test('excludes unpriced positions from the totals', () {
      final summary = PortfolioSummary.from(
        [
          holding(symbol: 'AAPL', shares: 10, costPerShare: 100),
          holding(symbol: 'ZZZZ', shares: 10, costPerShare: 100),
        ],
        {'AAPL': quote(symbol: 'AAPL', price: 120)},
      );

      expect(summary.unpricedCount, 1);
      expect(summary.primaryTotals!.positionCount, 1);
      expect(summary.primaryTotals!.marketValue, 1200);
      expect(summary.primaryTotals!.costBasis, 1000);
      // The unpriced holding is still listed so the user can see it.
      expect(summary.positions.length, 2);
      expect(summary.positions.last.symbol, 'ZZZZ');
    });

    test('orders positions by market value with unpriced ones last', () {
      final summary = PortfolioSummary.from(
        [
          holding(symbol: 'SMALL', shares: 1, costPerShare: 10),
          holding(symbol: 'BIG', shares: 100, costPerShare: 10),
          holding(symbol: 'NONE', shares: 5, costPerShare: 10),
        ],
        {
          'SMALL': quote(symbol: 'SMALL', price: 20),
          'BIG': quote(symbol: 'BIG', price: 30),
        },
      );

      expect(
        [for (final position in summary.positions) position.symbol],
        ['BIG', 'SMALL', 'NONE'],
      );
    });

    test('an empty portfolio has no totals', () {
      final summary = PortfolioSummary.from([], {});

      expect(summary.positionCount, 0);
      expect(summary.primaryCurrency, isNull);
      expect(summary.primaryTotals, isNull);
      expect(summary.orderedCurrencies, isEmpty);
    });
  });
}
