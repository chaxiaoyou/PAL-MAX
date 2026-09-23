import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

/// Records every symbol list the app asks for, so the tests can prove a symbol
/// is requested once rather than once per screen.
class _RecordingApi extends YahooFinanceApi {
  final calls = <List<String>>[];

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    calls.add(List.of(symbols));
    return [
      for (final symbol in symbols)
        Quote(
          symbol: symbol,
          name: symbol,
          lastPrice: 100,
          change: 1,
          changePercent: 1,
        ),
    ];
  }
}

/// Serves one good response, then fails like an unavailable backend.
class _FlakyApi extends YahooFinanceApi {
  var _served = false;

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    if (_served) {
      throw const YahooFinanceException('Quotes request failed with HTTP 500');
    }
    _served = true;
    return [
      for (final symbol in symbols)
        Quote(
          symbol: symbol,
          name: symbol,
          lastPrice: 100,
          change: 1,
          changePercent: 1,
        ),
    ];
  }
}

HoldingDraft _draft(String symbol) => HoldingDraft(
      symbol: symbol,
      name: symbol,
      shares: 1,
      costPerShare: 1,
      currency: 'USD',
    );

Future<void> _settle() async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test(
    'fetches a symbol shared by the watchlist and the portfolio once',
    () async {
      final store = await openStore('quote_board_test');
      final api = _RecordingApi();
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(store),
          yahooApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      // Reading the watchlist starts its load, which registers the default
      // symbols with the board.
      container.read(watchlistProvider);
      await _settle();
      expect(api.calls, hasLength(1));
      expect(api.calls.single, contains('AAPL'));

      // Narrowing to symbols the board already priced does not refetch.
      await container
          .read(watchlistProvider.notifier)
          .setSymbols(['AAPL', 'MSFT']);
      expect(api.calls, hasLength(1));

      // A holding the watchlist already covers is free too.
      await container.read(portfolioProvider.notifier).upsert(_draft('AAPL'));
      expect(api.calls, hasLength(1));

      // A symbol neither list has priced yet fetches the union once: AAPL
      // appears a single time even though both sources want it.
      await container.read(portfolioProvider.notifier).upsert(_draft('NVDA'));
      expect(api.calls, hasLength(2));
      expect(
        [...api.calls.last]..sort(),
        ['AAPL', 'MSFT', 'NVDA'],
      );

      // Prices for symbols nobody watches any more are dropped.
      expect(
        container.read(quoteBoardProvider).quotes.keys,
        unorderedEquals(['AAPL', 'MSFT', 'NVDA']),
      );
      await container.read(watchlistProvider.notifier).setSymbols([]);
      expect(
        container.read(quoteBoardProvider).quotes.keys,
        unorderedEquals(['AAPL', 'NVDA']),
      );
    },
    skip: isarUnavailable,
  );

  test(
    'keeps serving the last quotes after a failed refresh',
    () async {
      final store = await openStore('quote_board_failure_test');
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(store),
          yahooApiProvider.overrideWithValue(_FlakyApi()),
        ],
      );
      addTearDown(container.dispose);

      container.read(watchlistProvider);
      await _settle();
      expect(container.read(quoteBoardProvider).quotes, isNotEmpty);

      await container.read(quoteBoardProvider.notifier).refresh();
      final state = container.read(quoteBoardProvider);
      expect(state.error, 'Quotes request failed with HTTP 500');
      // The values stay usable; the error and the fetch time say they are old.
      expect(state.quotes, isNotEmpty);
      expect(state.lastFetch, isNotNull);
    },
    skip: isarUnavailable,
  );
}
