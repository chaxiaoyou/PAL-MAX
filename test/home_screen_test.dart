import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/screens/home_screen.dart';
import 'package:needhamcapital/services/yahoo_service.dart';
import 'package:needhamcapital/widgets/quote_card.dart';

import 'isar_harness.dart';

/// Serves canned quotes so the screen runs against the real provider tree
/// without touching the network.
class _FakeQuotesApi extends YahooFinanceApi {
  _FakeQuotesApi(this.bySymbol);

  final Map<String, Quote> bySymbol;

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => [
        for (final symbol in symbols)
          if (bySymbol[symbol] != null) bySymbol[symbol]!,
      ];
}

Quote _quote(String symbol) => Quote(
      symbol: symbol,
      name: '$symbol Corp.',
      lastPrice: 100,
      change: 1,
      changePercent: 1,
    );

Widget _app(Isar store) => ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(store),
        yahooApiProvider.overrideWithValue(
          _FakeQuotesApi({for (final s in defaultWatchlist) s: _quote(s)}),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );

void main() {
  setUpAll(loadTestFonts);

  testWidgets(
    'renders a card per watchlist symbol once quotes arrive',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'home_screen_test');
      await tester.pumpWidget(_app(store));
      await settleRealIo(tester);

      expect(find.byType(QuoteCard), findsNWidgets(defaultWatchlist.length));
      expect(find.text('AAPL'), findsOneWidget);
      // The status line reports the fetch instead of the placeholder.
      expect(find.textContaining('Last fetch: --'), findsNothing);
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'shows the empty state when every symbol is removed',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'home_empty_test');
      await tester.pumpWidget(_app(store));
      await settleRealIo(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await tester.runAsync(
        () => container.read(watchlistProvider.notifier).setSymbols([]),
      );
      await settleRealIo(tester);

      expect(find.text('Your watchlist is empty'), findsOneWidget);
      expect(find.byType(QuoteCard), findsNothing);
    },
    skip: isarUnavailable,
  );
}
