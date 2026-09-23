import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/screens/transactions_screen.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

class _QuietApi extends YahooFinanceApi {
  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => const [];
}

Holding _holding() => Holding()
  ..symbol = 'AAPL'
  ..name = 'Apple Inc.'
  ..shares = 10
  ..costPerShare = 100
  ..currency = 'USD'
  ..createdAt = DateTime(2026, 1, 1)
  ..updatedAt = DateTime(2026, 1, 1);

Widget _app(Isar store) => ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(store),
        yahooApiProvider.overrideWithValue(_QuietApi()),
      ],
      child: const MaterialApp(
        home: TransactionsScreen(
          symbol: 'AAPL',
          name: 'Apple Inc.',
          currency: 'USD',
        ),
      ),
    );

void main() {
  setUpAll(loadTestFonts);

  testWidgets(
    'a hand-entered position has no ledger until it is converted',
    (tester) async {
      final store = await openStoreInWidgetTest(
        tester,
        'transactions_manual',
        holdings: [_holding()],
      );
      await tester.pumpWidget(_app(store));
      await settleRealIo(tester);

      expect(find.text('10 shares'), findsOneWidget);
      expect(find.text(r'avg $100.00  ·  cost basis $1,000.00'), findsOneWidget);
      expect(find.text('Nothing recorded yet.'), findsOneWidget);
      // Without a ledger there is nothing to sell against, so the only way in
      // is to convert — or to keep editing by hand.
      expect(find.text('Track buys and sells instead'), findsOneWidget);
      expect(find.text('Edit manually'), findsOneWidget);
      expect(find.text('Add transaction'), findsNothing);
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'converting records an opening balance and a sell is then priced against it',
    (tester) async {
      final store = await openStoreInWidgetTest(
        tester,
        'transactions_convert',
        holdings: [_holding()],
      );
      await tester.pumpWidget(_app(store));
      await settleRealIo(tester);

      await tester.tap(find.text('Track buys and sells instead'));
      // Let the snackbar finish animating in, then dismiss it: a floating
      // snackbar is laid out relative to the floating action button, and the
      // test should not depend on that timing.
      await tester.pump(const Duration(milliseconds: 400));
      ScaffoldMessenger.of(
        tester.element(find.byType(TransactionsScreen)),
      ).hideCurrentSnackBar();
      await tester.pump(const Duration(milliseconds: 400));
      await settleRealIo(tester);
      // The action button scales in; it needs clock time before it can be hit.
      await tester.pump(const Duration(milliseconds: 400));
      // The manually entered position becomes the opening balance.
      expect(find.textContaining('Buy  ·'), findsOneWidget);
      expect(find.text('Opening balance'), findsOneWidget);
      expect(find.text('TRANSACTIONS · 1'), findsOneWidget);
      expect(find.text('Add transaction'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      // Let the sheet finish sliding up before reaching into it.
      await tester.pump();
      await settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Sell'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), '4');
      await tester.enterText(find.byType(TextField).at(1), '120');
      await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
      await tester.pump(const Duration(milliseconds: 400));
      await settleRealIo(tester);

      // 10 bought at 100, 4 sold at 120: 6 left at an unchanged average, and
      // 4 x (120 - 100) realised.
      expect(find.text('6 shares'), findsOneWidget);
      expect(find.text(r'avg $100.00  ·  cost basis $600.00'), findsOneWidget);
      expect(find.text(r'Realized +$80.00'), findsOneWidget);
      expect(find.text('from 1 sale'), findsOneWidget);
      expect(find.text('TRANSACTIONS · 2'), findsOneWidget);
    },
    skip: isarUnavailable,
  );
}
