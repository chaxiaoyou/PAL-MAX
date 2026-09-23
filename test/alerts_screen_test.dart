import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:needhamcapital/models/holding.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/screens/alerts_screen.dart';
import 'package:needhamcapital/services/alert_notifier.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

class _QuotesApi extends YahooFinanceApi {
  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => [
        for (final symbol in symbols)
          Quote(
            symbol: symbol,
            name: '$symbol Inc.',
            lastPrice: 250,
            change: 1,
            changePercent: 1,
          ),
      ];
}

class _SilentAlertNotifier implements AlertNotifier {
  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> notify({
    required int id,
    required String title,
    required String body,
  }) async {}
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
        yahooApiProvider.overrideWithValue(_QuotesApi()),
        alertNotifierProvider.overrideWithValue(_SilentAlertNotifier()),
      ],
      child: const MaterialApp(home: AlertsScreen()),
    );

/// Lets a sheet finish sliding up before reaching into it.
Future<void> _openSheet(WidgetTester tester) async {
  await tester.pump();
  await settleRealIo(tester);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets(
    'an alert can be created for a symbol the app already follows',
    (tester) async {
      final store = await openStoreInWidgetTest(
        tester,
        'alerts_screen_test',
        holdings: [_holding()],
      );
      await tester.pumpWidget(_app(store));
      await settleRealIo(tester);

      expect(find.text('No alerts yet'), findsOneWidget);

      await tester.tap(find.text('Add alert'));
      await _openSheet(tester);
      // The picker offers what the app already has prices for.
      expect(find.text('Watch a price'), findsOneWidget);

      await tester.tap(find.text('AAPL').last);
      await _openSheet(tester);
      // The level starts at the current price and can be edited from there.
      expect(find.textContaining('Now \$250.00'), findsOneWidget);

      await tester.tap(find.text('Create alert'));
      await tester.pump(const Duration(milliseconds: 400));
      await settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No alerts yet'), findsNothing);
      expect(find.textContaining('rises above \$250.00'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    },
    skip: isarUnavailable,
  );
}
