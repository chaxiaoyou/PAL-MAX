// Temporary visual dump used while tuning layout / palette. Delete after use.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/models/quote.dart';
import 'package:pjza/providers/providers.dart';
import 'package:pjza/screens/quote_detail_screen.dart';
import 'package:pjza/screens/root_shell.dart';
import 'package:pjza/screens/history_screen.dart';
import 'package:pjza/screens/search_screen.dart';
import 'package:pjza/screens/settings_screen.dart';
import 'package:pjza/screens/tools_screen.dart';
import 'package:pjza/theme/app_theme.dart';

import 'fake_yahoo_api.dart';
import 'isar_harness.dart';

class _ChartApi extends FakeYahooApi {
  _ChartApi(super.quotes);

  @override
  Future<List<ChartPoint>> fetchChart(
    String symbol, {
    required String range,
    required String interval,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return List.generate(
      80,
      (i) => ChartPoint(
        time: now - (79 - i) * 300,
        close: 180 + math.sin(i / 6) * 8 + i * 0.15,
      ),
    );
  }

  @override
  Future<List<NewsItem>> fetchNews(String symbol) async => [
        NewsItem(
          title: 'Alphabet beats estimates as cloud revenue accelerates',
          link: 'https://example.com/a',
          description: '',
          pubDate: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NewsItem(
          title: 'Analysts raise price targets across mega-cap tech',
          link: 'https://example.com/b',
          description: '',
          pubDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NewsItem(
          title: 'What the Fed decision means for growth stocks',
          link: 'https://example.com/c',
          description: '',
          pubDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
}

void main() {
  late Isar? isar;
  final hasIsarCore = isarCoreLibPath() != null;

  setUpAll(() async {
    isar = await openTestIsar('pjza_visual_dump');
  });

  tearDownAll(() async {
    await isar?.close();
  });

  final api = _ChartApi([
    fakeQuote(
      symbol: '^GSPC',
      name: 'S&P 500',
      price: 6200,
      changePercent: 0.42,
      quoteType: 'INDEX',
    ),
    fakeQuote(
      symbol: '^DJI',
      name: 'Dow Jones',
      price: 44000,
      changePercent: -0.18,
      quoteType: 'INDEX',
    ),
    fakeQuote(symbol: '^IXIC', name: 'Nasdaq', price: 20400, changePercent: 0.77, quoteType: 'INDEX'),
    fakeQuote(symbol: 'GOOG', name: 'Alphabet Inc.', price: 190.25, changePercent: 1.24),
    fakeQuote(symbol: 'AAPL', name: 'Apple Inc.', price: 232.5, changePercent: -0.64),
    fakeQuote(symbol: 'MSFT', name: 'Microsoft Corp', price: 415.8, changePercent: 0.33),
  ]);

  Widget wrap(Widget child, {bool dark = false}) => ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar!),
          yahooApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: child,
        ),
      );

  Future<void> mount(WidgetTester tester, Widget child, {bool dark = false}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(wrap(child, dark: dark));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('dump watchlist light', (tester) async {
    await mount(tester, const RootShell());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/01-watchlist-light.png'),
    );
  }, skip: !hasIsarCore);

  testWidgets('dump watchlist dark', (tester) async {
    await mount(tester, const RootShell(), dark: true);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/02-watchlist-dark.png'),
    );
  }, skip: !hasIsarCore);

  testWidgets('dump tools light', (tester) async {
    await mount(tester, const ToolsScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/03-tools-light.png'),
    );
  }, skip: !hasIsarCore);

  testWidgets('dump quote detail light', (tester) async {
    await mount(
      tester,
      QuoteDetailScreen(
        initialQuote: fakeQuote(
          symbol: 'GOOG',
          name: 'Alphabet Inc.',
          price: 190.25,
          changePercent: 1.24,
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/04-detail-light.png'),
    );
  }, skip: !hasIsarCore);

  testWidgets('dump history light', (tester) async {
    await mount(tester, const HistoryScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/05-history-light.png'),
    );
  }, skip: !hasIsarCore);

  testWidgets('dump settings dark', (tester) async {
    await mount(tester, const SettingsScreen(), dark: true);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/06-settings-dark.png'),
    );
  }, skip: !hasIsarCore);

  testWidgets('dump search light', (tester) async {
    await mount(tester, const SearchScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/visual/07-search-light.png'),
    );
  }, skip: !hasIsarCore);
}
