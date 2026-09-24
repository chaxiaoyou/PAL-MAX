import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/providers/providers.dart';
import 'package:pjza/screens/home_screen.dart';
import 'package:pjza/theme/app_theme.dart';

import 'fake_yahoo_api.dart';
import 'isar_harness.dart';

void main() {
  late Isar? isar;
  late FakeYahooApi api;
  final hasIsarCore = isarCoreLibPath() != null;

  setUpAll(() async {
    isar = await openTestIsar('pjza_home_test');
    api = FakeYahooApi([
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
      fakeQuote(
        symbol: 'GOOG',
        name: 'Alphabet Inc.',
        price: 190.25,
        changePercent: 1.24,
      ),
      fakeQuote(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        price: 232.5,
        changePercent: -0.64,
      ),
      fakeQuote(
        symbol: 'MSFT',
        name: 'Microsoft Corp',
        price: 415.8,
        changePercent: 0.33,
      ),
    ]);
  });

  tearDownAll(() async {
    await isar?.close();
  });

  Widget wrap() => ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar!),
          yahooApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const HomeScreen(),
        ),
      );

  /// Isar answers on the real event loop, which `testWidgets` fake time does
  /// not advance — so mount and wait inside [WidgetTester.runAsync].
  Future<void> mount(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(wrap());
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the index strip and the watchlist rows',
    (tester) async {
      await mount(tester);

      expect(find.text('Markets'), findsOneWidget);
      expect(find.text('Market indices'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);

      // Indices live in the hero strip; the others are listed as rows.
      expect(find.text('^GSPC'), findsOneWidget);
      expect(find.text('GOOG'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('MSFT'), findsOneWidget);

      // The default watchlist is what gets requested from the API.
      expect(api.lastRequested, containsAll(['^GSPC', '^DJI', 'GOOG']));
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'gainers / losers filters narrow the list',
    (tester) async {
      await mount(tester);

      await tester.tap(find.text('Gainers'));
      await tester.pumpAndSettle();
      expect(find.text('GOOG'), findsOneWidget);
      expect(find.text('MSFT'), findsOneWidget);
      expect(find.text('AAPL'), findsNothing);

      await tester.tap(find.text('Losers'));
      await tester.pumpAndSettle();
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('GOOG'), findsNothing);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'refreshing re-requests the watchlist',
    (tester) async {
      await mount(tester);

      final before = api.fetchCount;
      await tester.tap(find.byTooltip('Refresh now'));
      await tester.pumpAndSettle();
      expect(api.fetchCount, greaterThan(before));
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'swiping a row asks for confirmation first',
    (tester) async {
      await mount(tester);
      expect(find.text('AAPL'), findsOneWidget);

      await tester.drag(find.text('AAPL'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Remove symbol'), findsOneWidget);
      expect(find.textContaining('Remove AAPL'), findsOneWidget);

      // Cancelling keeps the row (and the symbol in the watchlist).
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('AAPL'), findsOneWidget);
      expect(api.lastRequested, contains('AAPL'));
    },
    skip: !hasIsarCore,
  );
}
