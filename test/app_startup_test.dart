import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/app.dart';
import 'package:pjza/data/isar_portfolio_store.dart';
import 'package:pjza/data/market_data.dart';
import 'package:pjza/data/portfolio_store.dart';
import 'package:pjza/domain/alert.dart';
import 'package:pjza/domain/transaction.dart';
import 'package:pjza/models/quote.dart';
import 'package:pjza/providers/providers.dart';

import 'isar_harness.dart';

/// No network in tests: quotes come from a stub.
class StubMarketData implements MarketDataProvider {
  @override
  Future<List<Quote>> quotes(List<String> symbols) async => [
        for (final symbol in symbols)
          Quote(
            symbol: symbol,
            name: symbol,
            lastPrice: 100,
            change: 1,
            changePercent: 1,
            previousClose: 99,
          ),
      ];

  @override
  Future<double?> fxRate(String from, String to) async => 1;
}

void main() {
  late Isar? isar;
  final hasIsarCore = isarCoreLibPath() != null;

  setUpAll(() async {
    isar = await openTestIsar('pjza_startup_test');
  });

  tearDownAll(() async {
    await isar?.close();
  });

  testWidgets(
    'the app boots into the portfolio shell with a seeded store',
    (tester) async {
      final store = IsarPortfolioStore(isar!);

      await tester.runAsync(() async {
        // Same path main() takes before runApp. Isar talks to the real event
        // loop, so it must run inside runAsync.
        await seedDemoPortfolioIfEmpty(store);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isarProvider.overrideWithValue(isar!),
              portfolioStoreProvider.overrideWithValue(store),
              marketDataProvider.overrideWithValue(StubMarketData()),
            ],
            child: const PalMaxApp(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      // Bounded pumping instead of pumpAndSettle: a persistent
      // CircularProgressIndicator never lets the tree settle, and we want to
      // observe that state rather than hang on it.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The portfolio tab is first, so the dashboard is what a cold start shows.
      expect(find.text('Portfolio'), findsWidgets);
      expect(find.text('Total value'), findsOneWidget);
      // A settled tree also proves nothing is rebuilding in a loop.
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'a store that throws does not leave the app on a blank screen',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isarProvider.overrideWithValue(isar!),
              portfolioStoreProvider.overrideWithValue(_BrokenStore()),
              marketDataProvider.overrideWithValue(StubMarketData()),
            ],
            child: const PalMaxApp(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Whatever the storage does, the shell must still render.
      expect(find.text('Portfolio'), findsWidgets);
      // And it must not surface an unhandled async error.
      expect(tester.takeException(), isNull);
    },
    skip: !hasIsarCore,
  );
}

class _BrokenStore implements PortfolioStore {
  @override
  Future<List<Alert>> loadAlerts() async => throw StateError('storage down');

  @override
  Future<List<Transaction>> loadTransactions() async =>
      throw StateError('storage down');

  @override
  Future<void> deleteAlert(String id) async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<void> saveAlert(Alert alert) async {}

  @override
  Future<void> saveTransaction(Transaction transaction) async {}
}
