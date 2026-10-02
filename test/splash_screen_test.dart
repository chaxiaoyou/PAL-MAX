import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/providers/providers.dart';
import 'package:pjza/screens/home_screen.dart';
import 'package:pjza/screens/root_shell.dart';
import 'package:pjza/screens/splash_screen.dart';
import 'package:pjza/screens/webview_screen.dart';

import 'fake_yahoo_api.dart';
import 'isar_harness.dart';

Widget _app(Isar store, FetchAppConf fetchAppConf) => ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(store),
        yahooApiProvider.overrideWithValue(FakeYahooApi(const [])),
      ],
      child: MaterialApp(home: SplashScreen(fetchAppConf: fetchAppConf)),
    );

/// Isar answers on the real event loop, which `testWidgets` fake time does not
/// advance — so widget mounts and the frames after them are driven inside
/// [WidgetTester.runAsync].
Future<void> settleRealIo(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
}

void main() {
  late Isar? isar;
  final hasIsarCore = isarCoreLibPath() != null;

  setUpAll(() async {
    isar = await openTestIsar('pjza_splash_test');
  });

  tearDownAll(() async {
    await isar?.close();
  });

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
      await tester.pumpWidget(_app(isar!, () async => null));

      expect(find.byType(SplashScreen), findsOneWidget);
      // The transit page holds for ~350ms rather than flashing, then hands
      // over with a 220ms fade.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await settleRealIo(tester);

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'keeps retrying when the check fails, then starts the app',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        _app(isar!, () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('backend unreachable');
          }
          return null;
        }),
      );

      await tester.pump();
      expect(attempts, 1);
      // Failing over is visible instead of an endless silent spinner, and the
      // app has not started on a guess.
      expect(find.text('Still connecting…'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await settleRealIo(tester);

      expect(attempts, 3);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
    skip: !hasIsarCore,
  );
}
