import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/data/market_data.dart';
import 'package:pjza/data/portfolio_store.dart';
import 'package:pjza/domain/alert.dart';
import 'package:pjza/domain/transaction.dart';
import 'package:pjza/l10n/app_localizations.dart';
import 'package:pjza/models/quote.dart';
import 'package:pjza/providers/providers.dart';
import 'package:pjza/screens/alerts_screen.dart';
import 'package:pjza/screens/portfolio_screen.dart';
import 'package:pjza/theme/app_theme.dart';

import 'isar_harness.dart';

/// Market data stub. Exercises the same interface the real providers implement,
/// which is the point of the abstraction: screens never see Yahoo.
class FakeMarketData implements MarketDataProvider {
  FakeMarketData(this._quotes);

  final Map<String, Quote> _quotes;
  int quoteCalls = 0;

  @override
  Future<List<Quote>> quotes(List<String> symbols) async {
    quoteCalls++;
    return [
      for (final symbol in symbols)
        if (_quotes.containsKey(symbol)) _quotes[symbol]!,
    ];
  }

  @override
  Future<double?> fxRate(String from, String to) async =>
      from == to ? 1 : null;
}

Quote quote(
  String symbol, {
  required double price,
  double previousClose = 0,
  String currency = 'MXN',
}) {
  return Quote(
    symbol: symbol,
    name: symbol,
    lastPrice: price,
    change: previousClose == 0 ? 0 : price - previousClose,
    changePercent:
        previousClose == 0 ? 0 : (price - previousClose) / previousClose * 100,
    currency: currency,
    previousClose: previousClose,
  );
}

Alert alert(String symbol, AlertKind kind, double threshold) => Alert(
      id: '$symbol-${kind.name}',
      symbol: symbol,
      kind: kind,
      threshold: threshold,
      createdAt: DateTime(2026, 6, 1),
    );

void main() {
  late Isar? isar;
  final hasIsarCore = isarCoreLibPath() != null;

  setUpAll(() async {
    isar = await openTestIsar('pjza_portfolio_test');
  });

  tearDownAll(() async {
    await isar?.close();
  });

  Widget wrap(Widget home, MarketDataProvider market, PortfolioStore store) {
    return ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar!),
        marketDataProvider.overrideWithValue(market),
        portfolioStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  Future<void> mount(
    WidgetTester tester,
    Widget home,
    MarketDataProvider market,
    PortfolioStore store,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(wrap(home, market, store));
      // Let the store's async load and the price fetch settle.
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pumpAndSettle();
  }

  InMemoryPortfolioStore holdings() => InMemoryPortfolioStore(
        transactions: [
          Transaction(
            id: 't1',
            symbol: 'WALMEX.MX',
            side: TradeSide.buy,
            quantity: 10,
            price: 100,
            fees: 50,
            executedAt: DateTime(2026, 2, 12),
          ),
          Transaction(
            id: 't2',
            symbol: 'FEMSAUBD.MX',
            side: TradeSide.buy,
            quantity: 5,
            price: 200,
            executedAt: DateTime(2026, 3, 20),
          ),
        ],
      );

  MarketDataProvider market() => FakeMarketData({
        'WALMEX.MX': quote('WALMEX.MX', price: 140, previousClose: 138),
        'FEMSAUBD.MX': quote('FEMSAUBD.MX', price: 190, previousClose: 195),
      });

  testWidgets(
    'portfolio dashboard shows totals, allocation and every position',
    (tester) async {
      await mount(tester, const PortfolioScreen(), market(), holdings());

      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Total value'), findsOneWidget);
      // WALMEX 10 × 140 + FEMSA 5 × 190 = 2350
      expect(find.textContaining('2,350.00'), findsWidgets);

      expect(find.text('WALMEX.MX'), findsWidgets);
      expect(find.text('FEMSAUBD.MX'), findsWidgets);
      expect(find.text('Avg cost'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Positions'), findsOneWidget);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'unpriced holdings are flagged instead of counted as zero',
    (tester) async {
      final partial = FakeMarketData({
        'WALMEX.MX': quote('WALMEX.MX', price: 140, previousClose: 138),
      });

      await mount(tester, const PortfolioScreen(), partial, holdings());

      expect(
        find.text('Some holdings could not be priced — totals are partial.'),
        findsOneWidget,
      );
      expect(find.textContaining('FEMSAUBD.MX'), findsWidgets);
      expect(find.textContaining('1,400.00'), findsWidgets);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'empty portfolio explains what to do instead of showing zeros',
    (tester) async {
      await mount(
        tester,
        const PortfolioScreen(),
        market(),
        InMemoryPortfolioStore(),
      );

      expect(find.text('No positions yet'), findsOneWidget);
      expect(find.text('Add transaction'), findsWidgets);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'alerts list states the distance to each threshold',
    (tester) async {
      final store = InMemoryPortfolioStore(
        alerts: [
          alert('WALMEX.MX', AlertKind.priceAbove, 150),
          alert('FEMSAUBD.MX', AlertKind.priceAbove, 150),
        ],
      );

      await mount(tester, const AlertsScreen(), market(), store);

      expect(find.text('Price alerts'), findsOneWidget);
      // WALMEX (140) is 10 away from 150; FEMSA (190) has already crossed it.
      expect(find.textContaining('10 to go'), findsOneWidget);
      expect(find.text('Threshold crossed'), findsOneWidget);
      expect(find.text('Armed'), findsOneWidget);
    },
    skip: !hasIsarCore,
  );
}
