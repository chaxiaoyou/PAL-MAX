import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/dividend.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/screens/portfolio_screen.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

/// Serves canned quotes so the test exercises the real store→provider→UI path
/// without touching the network.
class _FakeQuotesApi extends YahooFinanceApi {
  _FakeQuotesApi(this.bySymbol, {this.dividends = const {}});

  final Map<String, Quote> bySymbol;
  final Map<String, List<DividendPayment>> dividends;

  @override
  Future<List<DividendPayment>> fetchDividends(
    String symbol, {
    String range = '2y',
  }) async =>
      dividends[symbol] ?? const [];

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => [
        for (final symbol in symbols)
          if (bySymbol[symbol] != null) bySymbol[symbol]!,
      ];

  @override
  Future<List<SearchResult>> search(String query) async => [
        for (final symbol in bySymbol.keys)
          if (symbol.toUpperCase().startsWith(query.toUpperCase()))
            SearchResult(
              symbol: symbol,
              name: bySymbol[symbol]!.name,
              exchange: 'NasdaqGS',
              type: 'Equity',
            ),
      ];
}

Quote _quote({
  required String symbol,
  required double price,
  required double change,
  required double changePercent,
  String currency = 'USD',
}) {
  return Quote(
    symbol: symbol,
    name: '$symbol Corp.',
    lastPrice: price,
    change: change,
    changePercent: changePercent,
    currency: currency,
  );
}

/// Prices the position once, then behaves like a failing backend.
class _RefreshFailsAfterFirstCallApi extends YahooFinanceApi {
  _RefreshFailsAfterFirstCallApi(this.bySymbol);

  final Map<String, Quote> bySymbol;
  var _served = false;

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    if (_served) {
      throw const YahooFinanceException('Quotes request failed with HTTP 500');
    }
    _served = true;
    return [
      for (final symbol in symbols)
        if (bySymbol[symbol] != null) bySymbol[symbol]!,
    ];
  }
}

Holding _holding({
  required String symbol,
  required String name,
  required double shares,
  required double costPerShare,
  String currency = 'USD',
}) {
  return Holding()
    ..symbol = symbol
    ..name = name
    ..shares = shares
    ..costPerShare = costPerShare
    ..currency = currency
    ..createdAt = DateTime(2026, 1, 1)
    ..updatedAt = DateTime(2026, 1, 1);
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets(
    'values stored holdings and shows profit against the cost basis',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'portfolio_value', holdings: [
        _holding(
          symbol: 'AAPL',
          name: 'Apple Inc.',
          shares: 10,
          costPerShare: 100,
        ),
        _holding(
          symbol: 'MSFT',
          name: 'Microsoft Corp.',
          shares: 5,
          costPerShare: 200,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(
              _FakeQuotesApi({
                'AAPL': _quote(
                  symbol: 'AAPL',
                  price: 120,
                  change: 2,
                  changePercent: 1.69,
                ),
                'MSFT': _quote(
                  symbol: 'MSFT',
                  price: 180,
                  change: -3,
                  changePercent: -1.64,
                ),
              }),
            ),
          ],
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      );
      await settleRealIo(tester);

      // AAPL: 10 x 120 = 1,200 on 1,000 cost. MSFT: 5 x 180 = 900 on 1,000.
      // Hero: 2,100 value, 2,000 cost, +100 profit (5.00%), +5.00 today.
      expect(find.text(r'$2,100.00'), findsOneWidget);
      expect(find.text(r'$2,000.00'), findsOneWidget);
      expect(find.text(r'+$100.00'), findsOneWidget);
      expect(find.text('+5.00%'), findsOneWidget);
      expect(find.text(r'+$5.00 (+0.24%)'), findsOneWidget);

      // Each row is priced on its own, with its own profit or loss.
      expect(find.text(r'$1,200.00'), findsOneWidget);
      expect(find.text(r'+$200.00'), findsOneWidget);
      expect(find.text('+20.00%'), findsOneWidget);
      expect(find.text(r'$900.00'), findsOneWidget);
      expect(find.text(r'-$100.00'), findsOneWidget);
      expect(find.text('-10.00%'), findsOneWidget);

      // The row shows the share count and the cost basis per share.
      expect(find.text(r'10 @ $100.00'), findsOneWidget);
      expect(find.text(r'5 @ $200.00'), findsOneWidget);
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'leaves a holding without a quote out of the totals',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'portfolio_unpriced', holdings: [
        _holding(
          symbol: 'ZZZZ',
          name: 'Unknown Corp.',
          shares: 5,
          costPerShare: 10,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(_FakeQuotesApi(const {})),
          ],
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      );
      await settleRealIo(tester);

      expect(find.text('no quote'), findsOneWidget);
      expect(find.textContaining('has no live quote'), findsOneWidget);
      expect(
        find.text('Waiting for the first quote to value these holdings.'),
        findsOneWidget,
      );
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'lays out at phone width with long names and large numbers',
    (tester) async {
      // 360 x 780 dp phone. A RenderFlex overflow is reported as a test
      // failure, so getting to the assertions proves the tab fits.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final store = await openStoreInWidgetTest(tester, 'portfolio_layout', holdings: [
        _holding(
          symbol: 'BRK.B',
          name: 'Berkshire Hathaway Inc. Class B',
          shares: 12345.6789,
          costPerShare: 482.15,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(
              _FakeQuotesApi(
                {
                  'BRK.B': _quote(
                    symbol: 'BRK.B',
                    price: 512.40,
                    change: 1.15,
                    changePercent: 0.22,
                  ),
                },
                // A dividend too, so the narrowest layout is also the densest.
                dividends: {
                  'BRK.B': [
                    DividendPayment(
                      symbol: 'BRK.B',
                      amount: 0.25,
                      date: DateTime.now()
                          .toUtc()
                          .subtract(const Duration(days: 30)),
                    ),
                  ],
                },
              ),
            ),
          ],
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      );
      await settleRealIo(tester);

      expect(find.text('BRK.B'), findsOneWidget);
      expect(find.text('Berkshire Hathaway Inc. Class B'), findsOneWidget);
      expect(
        find.text(r'12,345.6789 @ $482.15  ·  $3,086.42/yr'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'adds a holding through the editor sheet',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'portfolio_add');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(
              _FakeQuotesApi({
                'AAPL': _quote(
                  symbol: 'AAPL',
                  price: 120,
                  change: 2,
                  changePercent: 1.69,
                ),
              }),
            ),
          ],
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      );
      await settleRealIo(tester);
      expect(find.text('No holdings yet'), findsOneWidget);

      await tester.tap(find.text('Add a holding'));
      await settleRealIo(tester);

      // Symbol field: type, let the search debounce fire, then pick the match.
      await tester.enterText(find.byType(TextField).first, 'AA');
      await tester.pump(const Duration(milliseconds: 400));
      await settleRealIo(tester);
      await tester.tap(find.text('AAPL'));
      await settleRealIo(tester);

      // Picking resolves the live quote, which fills in the currency.
      expect(find.text('AAPL Corp. · USD'), findsOneWidget);
      expect(find.text('Current 120'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), '10');
      await tester.enterText(find.byType(TextField).at(2), '100');
      await tester.tap(find.text('Add to portfolio'));
      await tester.pump(const Duration(milliseconds: 400));
      await settleRealIo(tester);

      expect(find.text('No holdings yet'), findsNothing);
      expect(find.text('AAPL added to your portfolio'), findsOneWidget);
      expect(find.text(r'10 @ $100.00'), findsOneWidget);
      // The hero total and the single position row carry the same numbers.
      expect(find.text(r'$1,200.00'), findsNWidgets(2));
      expect(find.text('+20.00%'), findsNWidgets(2));
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'keeps the last known quotes when a refresh fails',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'portfolio_stale', holdings: [
        _holding(
          symbol: 'AAPL',
          name: 'Apple Inc.',
          shares: 10,
          costPerShare: 100,
        ),
      ]);
      // The first fetch prices the position; every later one fails.
      final api = _RefreshFailsAfterFirstCallApi({
        'AAPL': _quote(
          symbol: 'AAPL',
          price: 120,
          change: 2,
          changePercent: 1.69,
        ),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(api),
          ],
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      );
      await settleRealIo(tester);
      // Hero total return and the single position row agree.
      expect(find.text(r'+$200.00'), findsNWidgets(2));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PortfolioScreen)),
      );
      await tester.runAsync(
        () => container.read(quoteBoardProvider.notifier).refresh(),
      );
      await settleRealIo(tester);

      expect(find.text('Quotes request failed with HTTP 500'), findsOneWidget);
      // The last good values stay on screen instead of blanking out.
      expect(find.text(r'$1,200.00'), findsNWidgets(2));
      expect(find.text(r'+$200.00'), findsNWidgets(2));
      expect(find.text('no quote'), findsNothing);
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'shows trailing dividend income and the yield on cost',
    (tester) async {
      final store = await openStoreInWidgetTest(
        tester,
        'portfolio_dividends',
        holdings: [
          _holding(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            shares: 10,
            costPerShare: 100,
          ),
        ],
      );
      final paidAt = DateTime.now().toUtc().subtract(const Duration(days: 30));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(store),
            yahooApiProvider.overrideWithValue(
              _FakeQuotesApi(
                {
                  'AAPL': _quote(
                    symbol: 'AAPL',
                    price: 120,
                    change: 2,
                    changePercent: 1.69,
                  ),
                },
                dividends: {
                  'AAPL': [
                    DividendPayment(
                      symbol: 'AAPL',
                      amount: 0.25,
                      date: paidAt,
                    ),
                  ],
                },
              ),
            ),
          ],
          child: const MaterialApp(home: PortfolioScreen()),
        ),
      );
      await settleRealIo(tester);

      expect(find.text('DIVIDEND INCOME · 12 MO'), findsOneWidget);
      // 0.25 per share x 10 shares, against a 1,000 cost basis.
      expect(find.text(r'$2.50'), findsOneWidget);
      expect(find.text('0.25% yield on cost'), findsOneWidget);
      expect(find.text(r'10 @ $100.00  ·  $2.50/yr'), findsOneWidget);
      expect(
        find.textContaining('Estimated from the shares you hold today'),
        findsOneWidget,
      );
    },
    skip: isarUnavailable,
  );
}
