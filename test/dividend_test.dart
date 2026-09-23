import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/dividend.dart';
import 'package:needhamcapital/models/dividend_income.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/position_ledger.dart';
import 'package:needhamcapital/models/portfolio_math.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/models/transaction.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

/// A chart response in the shape Yahoo returns: dividends keyed by timestamp,
/// amount per share plus the same timestamp as `date`.
const _chartWithDividends = '''
{
  "chart": {
    "result": [
      {
        "meta": {"currency": "USD", "symbol": "AAPL"},
        "timestamp": [1770000000, 1780000000],
        "events": {
          "dividends": {
            "1780000000": {"amount": 0.27, "date": 1780000000},
            "1770000000": {"amount": 0.26, "date": 1770000000}
          },
          "splits": {
            "1750000000": {"date": 1750000000, "numerator": 4, "denominator": 1}
          }
        }
      }
    ],
    "error": null
  }
}
''';

class _DividendApi extends YahooFinanceApi {
  _DividendApi(this.bySymbol);

  final Map<String, List<DividendPayment>> bySymbol;
  final requested = <String>[];

  @override
  Future<List<DividendPayment>> fetchDividends(
    String symbol, {
    String range = '2y',
  }) async {
    requested.add(symbol);
    final payments = bySymbol[symbol];
    if (payments == null) {
      throw const YahooFinanceException('Dividend request failed with HTTP 404');
    }
    return payments;
  }

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => const [];
}

Holding _holding({
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

Quote _quote(String symbol, {String currency = 'USD'}) => Quote(
      symbol: symbol,
      name: symbol,
      lastPrice: 120,
      change: 1,
      changePercent: 1,
      currency: currency,
    );

PortfolioSummary _portfolio(List<Holding> holdings) => PortfolioSummary.from(
      holdings,
      {
        for (final holding in holdings)
          holding.symbol: _quote(holding.symbol, currency: holding.currency),
      },
    );

Future<void> _settle() async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('parseDividends', () {
    test('reads amounts and dates off the chart events', () {
      final payments = YahooFinanceApi.parseDividends(
        _chartWithDividends,
        symbol: 'AAPL',
      );

      expect(payments, hasLength(2));
      // Oldest first, regardless of the order Yahoo keys them in.
      expect(payments.first.amount, 0.26);
      expect(payments.last.amount, 0.27);
      expect(payments.first.symbol, 'AAPL');
      expect(
        payments.first.date,
        DateTime.fromMillisecondsSinceEpoch(1770000000 * 1000, isUtc: true),
      );
    });

    test('treats a response without dividends as no payments', () {
      expect(
        YahooFinanceApi.parseDividends(
          '{"chart":{"result":[{"meta":{"symbol":"BRK.A"}}]}}',
          symbol: 'BRK.A',
        ),
        isEmpty,
      );
      expect(
        YahooFinanceApi.parseDividends('not json at all', symbol: 'AAPL'),
        isEmpty,
      );
    });

    test('skips entries that are missing an amount or a date', () {
      final payments = YahooFinanceApi.parseDividends(
        '{"chart":{"result":[{"events":{"dividends":{'
        '"1":{"amount":0.5,"date":1770000000},'
        '"2":{"amount":"nope","date":1770000000},'
        '"3":{"date":1770000000}'
        '}}}]}}',
        symbol: 'AAPL',
      );

      expect(payments, hasLength(1));
      expect(payments.single.amount, 0.5);
    });
  });

  group('DividendSummary', () {
    final asOf = DateTime.utc(2026, 9, 22);

    test('counts only payments inside the trailing year', () {
      final summary = DividendSummary.from(
        portfolio: _portfolio([_holding(symbol: 'AAPL', shares: 10)]),
        payments: {
          'AAPL': [
            // 478 days before asOf: outside the window.
            DividendPayment(
              symbol: 'AAPL',
              amount: 0.22,
              date: DateTime.utc(2025, 6, 1),
            ),
            DividendPayment(
              symbol: 'AAPL',
              amount: 0.25,
              date: DateTime.utc(2025, 11, 1),
            ),
            DividendPayment(
              symbol: 'AAPL',
              amount: 0.27,
              date: DateTime.utc(2026, 8, 15),
            ),
          ],
        },
        asOf: asOf,
      );

      final income = summary.incomes.single;
      expect(income.paymentCount, 2);
      // (0.25 + 0.27) per share x 10 shares.
      expect(income.trailingAmount, closeTo(5.2, 1e-9));
      expect(summary.trailingFor('USD'), closeTo(5.2, 1e-9));
      // 5.20 on a 1,000 cost basis.
      expect(summary.yieldOnCost('USD'), closeTo(0.52, 1e-9));
    });

    test('scales with the share count held today', () {
      final payments = {
        'AAPL': [
          DividendPayment(
            symbol: 'AAPL',
            amount: 0.25,
            date: DateTime.utc(2026, 8, 15),
          ),
        ],
      };

      final one = DividendSummary.from(
        portfolio: _portfolio([_holding(symbol: 'AAPL', shares: 1)]),
        payments: payments,
        asOf: asOf,
      );
      final hundred = DividendSummary.from(
        portfolio: _portfolio([_holding(symbol: 'AAPL', shares: 100)]),
        payments: payments,
        asOf: asOf,
      );

      expect(one.trailingFor('USD'), closeTo(0.25, 1e-9));
      expect(hundred.trailingFor('USD'), closeTo(25, 1e-9));
    });

    test('keeps currencies apart', () {
      final summary = DividendSummary.from(
        portfolio: _portfolio([
          _holding(symbol: 'AAPL', shares: 10),
          _holding(symbol: 'AIR.PA', shares: 2, currency: 'EUR'),
        ]),
        payments: {
          'AAPL': [
            DividendPayment(
              symbol: 'AAPL',
              amount: 0.25,
              date: DateTime.utc(2026, 8, 15),
            ),
          ],
          'AIR.PA': [
            DividendPayment(
              symbol: 'AIR.PA',
              amount: 1.5,
              date: DateTime.utc(2026, 5, 1),
            ),
          ],
        },
        asOf: asOf,
      );

      expect(summary.trailingFor('USD'), closeTo(2.5, 1e-9));
      expect(summary.trailingFor('EUR'), closeTo(3, 1e-9));
      expect(summary.trailingFor('GBP'), 0);
    });

    test('reports no yield when there is no cost basis', () {
      final summary = DividendSummary.from(
        portfolio: _portfolio([
          _holding(symbol: 'GIFT', shares: 5, costPerShare: 0),
        ]),
        payments: {
          'GIFT': [
            DividendPayment(
              symbol: 'GIFT',
              amount: 0.5,
              date: DateTime.utc(2026, 8, 15),
            ),
          ],
        },
        asOf: asOf,
      );

      expect(summary.trailingFor('USD'), closeTo(2.5, 1e-9));
      expect(summary.yieldOnCost('USD'), isNull);
    });

    test('lists payers largest first and leaves non-payers out of the list', () {
      final summary = DividendSummary.from(
        portfolio: _portfolio([
          _holding(symbol: 'SMALL', shares: 1, costPerShare: 10),
          _holding(symbol: 'BIG', shares: 100, costPerShare: 10),
          _holding(symbol: 'NONE', shares: 5, costPerShare: 10),
        ]),
        payments: {
          'SMALL': [
            DividendPayment(
              symbol: 'SMALL',
              amount: 0.5,
              date: DateTime.utc(2026, 8, 15),
            ),
          ],
          'BIG': [
            DividendPayment(
              symbol: 'BIG',
              amount: 2,
              date: DateTime.utc(2026, 8, 15),
            ),
          ],
        },
        asOf: asOf,
      );

      expect([for (final income in summary.payers) income.symbol], ['BIG', 'SMALL']);
      expect(summary.payingCount, 2);
      expect(summary.hasAny, isTrue);
    });

    test('an empty portfolio has nothing to report', () {
      final summary = DividendSummary.from(
        portfolio: PortfolioSummary.empty,
        payments: const {},
      );

      expect(summary.hasAny, isFalse);
      expect(summary.payers, isEmpty);
      expect(summary.yieldOnCost('USD'), isNull);
    });

    test('a ledger credits each payment to the shares held on that date', () {
      final ledger = PositionLedger.from('AAPL', [
        Transaction()
          ..symbol = 'AAPL'
          ..kind = TransactionKind.buy.storageValue
          ..shares = 4
          ..pricePerShare = 100
          ..fee = 0
          ..tradedAt = DateTime(2026, 8, 1)
          ..currency = 'USD',
      ]);
      final payments = {
        'AAPL': [
          // Paid before the position existed: not income.
          DividendPayment(
            symbol: 'AAPL',
            amount: 0.25,
            date: DateTime.utc(2026, 5, 1),
          ),
          DividendPayment(
            symbol: 'AAPL',
            amount: 0.27,
            date: DateTime.utc(2026, 8, 15),
          ),
        ],
      };
      // The hand-entered position claims 10 shares; the ledger knows better.
      final portfolio = _portfolio([_holding(symbol: 'AAPL', shares: 10)]);

      final withLedger = DividendSummary.from(
        portfolio: portfolio,
        payments: payments,
        ledgers: {'AAPL': ledger},
        asOf: asOf,
      );
      final withoutLedger = DividendSummary.from(
        portfolio: portfolio,
        payments: payments,
        asOf: asOf,
      );

      // Only the August payment, on the 4 shares held that day.
      expect(withLedger.trailingFor('USD'), closeTo(1.08, 1e-9));
      expect(withLedger.incomes.single.paymentCount, 1);
      expect(withLedger.estimatedCount, 0);
      // Without a ledger both payments are applied to today's 10 shares.
      expect(withoutLedger.trailingFor('USD'), closeTo(5.2, 1e-9));
      expect(withoutLedger.incomes.single.paymentCount, 2);
      expect(withoutLedger.estimatedCount, 1);
    });
  });

  group('DividendNotifier', () {
    test(
      'fetches each held symbol once and remembers what failed',
      () async {
        final store = await openStore(
          'dividend_provider_test',
          holdings: [
            _holding(symbol: 'AAPL'),
            _holding(symbol: 'ZZZZ'),
          ],
        );
        final api = _DividendApi({
          'AAPL': [
            DividendPayment(
              symbol: 'AAPL',
              amount: 0.25,
              date: DateTime.now().toUtc().subtract(const Duration(days: 30)),
            ),
          ],
        });
        final container = ProviderContainer(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(api),
          ],
        );
        addTearDown(container.dispose);

        container.read(dividendProvider);
        await _settle();

        expect(api.requested..sort(), ['AAPL', 'ZZZZ']);
        final state = container.read(dividendProvider);
        expect(state.payments['AAPL'], hasLength(1));
        expect(state.failed, {'ZZZZ'});
        expect(state.loading, isFalse);

        // A retry asks only for the symbol that failed.
        api.requested.clear();
        await container.read(dividendProvider.notifier).retryFailed();
        await _settle();
        expect(api.requested, ['ZZZZ']);
      },
      skip: isarUnavailable,
    );
  });
}
