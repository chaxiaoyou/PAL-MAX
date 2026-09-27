import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/data/isar_portfolio_store.dart';
import 'package:pjza/data/portfolio_store.dart';
import 'package:pjza/domain/alert.dart';
import 'package:pjza/domain/transaction.dart';

import 'isar_harness.dart';

void main() {
  // Not `late`: setUp reads it to close the previous instance, and a late
  // variable would throw on the very first read.
  Isar? isar;
  late IsarPortfolioStore store;
  final hasIsarCore = isarCoreLibPath() != null;

  setUp(() async {
    if (!hasIsarCore) return;
    // Fresh database per test: these are persistence assertions, not algo ones.
    await isar?.close();
    isar = await openTestIsar('pjza_store_test_${DateTime.now().microsecond}');
    store = IsarPortfolioStore(isar!);
  });

  tearDownAll(() async {
    await isar?.close();
  });

  Transaction trade(
    String id, {
    String symbol = 'WALMEX.MX',
    double quantity = 10,
    double price = 100,
    DateTime? at,
  }) {
    return Transaction(
      id: id,
      symbol: symbol,
      side: TradeSide.buy,
      quantity: quantity,
      price: price,
      fees: 12,
      executedAt: at ?? DateTime(2026, 2, 12),
      note: 'nota',
    );
  }

  group('IsarPortfolioStore', () {
    test('round-trips transactions in execution order', () async {
      await store.saveTransaction(trade('b', at: DateTime(2026, 5, 1)));
      await store.saveTransaction(trade('a', at: DateTime(2026, 1, 1)));

      final loaded = await store.loadTransactions();

      expect(loaded.map((t) => t.id).toList(), ['a', 'b']);
      expect(loaded.first.symbol, 'WALMEX.MX');
      expect(loaded.first.side, TradeSide.buy);
      expect(loaded.first.fees, 12);
      expect(loaded.first.note, 'nota');
    });

    test('re-saving the same id updates in place instead of duplicating',
        () async {
      await store.saveTransaction(trade('a', quantity: 10));
      await store.saveTransaction(trade('a', quantity: 25));

      final loaded = await store.loadTransactions();

      expect(loaded, hasLength(1));
      expect(loaded.single.quantity, 25);
    });

    test('deletes only the requested transaction', () async {
      await store.saveTransaction(trade('a'));
      await store.saveTransaction(trade('b'));

      await store.deleteTransaction('a');

      final loaded = await store.loadTransactions();
      expect(loaded.map((t) => t.id).toList(), ['b']);
    });

    test('round-trips alert state, including the fired marker', () async {
      final alert = Alert(
        id: 'alert-1',
        symbol: 'CEMEXCPO.MX',
        kind: AlertKind.percentChangeBelow,
        threshold: -3,
        createdAt: DateTime(2026, 6, 2),
        triggeredAt: DateTime(2026, 6, 9, 14, 30),
        note: 'revisar',
      );

      await store.saveAlert(alert);
      final loaded = (await store.loadAlerts()).single;

      expect(loaded.id, 'alert-1');
      expect(loaded.kind, AlertKind.percentChangeBelow);
      expect(loaded.threshold, -3);
      expect(loaded.isTriggered, isTrue);
      expect(loaded.triggeredAt, DateTime(2026, 6, 9, 14, 30));
      expect(loaded.note, 'revisar');

      // Re-arming must survive a reload, otherwise a restart re-notifies.
      await store.saveAlert(loaded.copyWith(clearTriggeredAt: true));
      final rearmed = (await store.loadAlerts()).single;
      expect(rearmed.isTriggered, isFalse);
      expect(rearmed.isArmed, isTrue);
    });

    test('deletes alerts by the caller-owned id', () async {
      await store.saveAlert(
        Alert(
          id: 'alert-1',
          symbol: 'WALMEX.MX',
          kind: AlertKind.priceAbove,
          threshold: 70,
          createdAt: DateTime(2026, 6, 1),
        ),
      );

      await store.deleteAlert('alert-1');

      expect(await store.loadAlerts(), isEmpty);
    });
  }, skip: !hasIsarCore);

  group('seedDemoPortfolioIfEmpty', () {
    test('fills an empty store', () async {
      await seedDemoPortfolioIfEmpty(store);

      expect(await store.loadTransactions(), isNotEmpty);
      expect(await store.loadAlerts(), isNotEmpty);
    });

    test('never touches a store that already has data', () async {
      await store.saveTransaction(trade('mine'));

      await seedDemoPortfolioIfEmpty(store);

      final loaded = await store.loadTransactions();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'mine');
      expect(await store.loadAlerts(), isEmpty);
    });
  }, skip: !hasIsarCore);
}
