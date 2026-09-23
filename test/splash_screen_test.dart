import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:needhamcapital/models/quote.dart';
import 'package:needhamcapital/providers/providers.dart';
import 'package:needhamcapital/screens/home_screen.dart';
import 'package:needhamcapital/screens/root_shell.dart';
import 'package:needhamcapital/screens/splash_screen.dart';
import 'package:needhamcapital/screens/webview_screen.dart';
import 'package:needhamcapital/services/yahoo_service.dart';

import 'isar_harness.dart';

class _QuietApi extends YahooFinanceApi {
  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => const [];
}

Widget _app(Isar store, FetchAppConf fetchAppConf) => ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(store),
        yahooApiProvider.overrideWithValue(_QuietApi()),
      ],
      child: MaterialApp(home: SplashScreen(fetchAppConf: fetchAppConf)),
    );

void main() {
  setUpAll(loadTestFonts);

  group('destinationFor', () {
    test('no steer means the native app', () {
      expect(destinationFor(null), StartupDestination.main);
      expect(destinationFor(''), StartupDestination.main);
      expect(destinationFor('   '), StartupDestination.main);
    });

    test('a steer URL means the web page', () {
      expect(
        destinationFor('https://starv.hscrespro.com'),
        StartupDestination.web,
      );
    });
  });

  group('pageFor', () {
    // Constructing the screens is enough to check the choice: it is only
    // building a web view that needs a platform implementation.
    test('routes a steer to the web view, trimmed', () {
      final page = pageFor(StartupDestination.web, ' https://example.com ');

      expect(page, isA<WebViewScreen>());
      expect((page as WebViewScreen).url, 'https://example.com');
    });

    test('routes an empty steer to the native app', () {
      expect(pageFor(StartupDestination.main, null), isA<RootShell>());
    });
  });

  testWidgets(
    'starts the native app when the backend has no steer',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'splash_main_test');
      await tester.pumpWidget(_app(store, () async => null));

      expect(find.byType(SplashScreen), findsOneWidget);
      // The splash holds for a moment rather than flashing, then hands over
      // with a 220ms fade.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
    skip: isarUnavailable,
  );

  testWidgets(
    'keeps retrying when the check fails, then starts the app',
    (tester) async {
      final store = await openStoreInWidgetTest(tester, 'splash_retry_test');
      var attempts = 0;
      await tester.pumpWidget(
        _app(store, () async {
          attempts++;
          if (attempts < 3) {
            throw const YahooFinanceException('backend unreachable');
          }
          return null;
        }),
      );

      await tester.pump();
      expect(attempts, 1);
      // Failing over is visible instead of an endless silent spinner.
      expect(find.text('Still connecting…'), findsOneWidget);
      // And the app has not started on a guess.
      expect(find.byType(HomeScreen), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(attempts, 3);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
    skip: isarUnavailable,
  );
}
