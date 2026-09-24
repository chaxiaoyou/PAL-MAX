import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/data/tools.dart';
import 'package:pjza/models/app_setting.dart';
import 'package:pjza/providers/providers.dart';
import 'package:pjza/screens/tools_screen.dart';
import 'package:pjza/theme/app_theme.dart';

import 'isar_harness.dart';

void main() {
  late Isar? isar;
  final hasIsarCore = isarCoreLibPath() != null;

  setUpAll(() async {
    isar = await openTestIsar('pjza_tools_test');
  });

  tearDownAll(() async {
    await isar?.close();
  });

  Widget wrap() => ProviderScope(
        overrides: [isarProvider.overrideWithValue(isar!)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const ToolsScreen(),
        ),
      );

  /// Isar answers on the real event loop, which `testWidgets` fake time does
  /// not advance — so mount and flush inside [WidgetTester.runAsync].
  Future<void> mount(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(wrap());
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'groups tools by category with a starter pin rail',
    (tester) async {
      await mount(tester);

      expect(find.text('Calculators'), findsOneWidget);
      expect(find.text('${appTools.length} calculators'), findsOneWidget);
      expect(find.text('Start here'), findsOneWidget);
      expect(find.text('Trading'), findsOneWidget);
      expect(find.text('Investment'), findsOneWidget);

      // A pinned tool shows in the rail, not in the section list.
      expect(find.text('Risk / Reward'), findsOneWidget);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'search filters down to matching calculators',
    (tester) async {
      await mount(tester);

      await tester.tap(find.byTooltip('Search calculators'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'dividend');
      await tester.pumpAndSettle();

      expect(find.text('Dividend Reinvest'), findsOneWidget);
      expect(find.text('Trading'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No calculator matches'), findsOneWidget);
    },
    skip: !hasIsarCore,
  );

  testWidgets(
    'pinning a tool moves it into the rail',
    (tester) async {
      // Persist favourites the way the star toggle does, then mount so the
      // provider reads them back from Isar.
      await tester.runAsync(() async {
        await isar!.writeTxn(
          () => isar!.appSettings.put(
            AppSetting()
              ..key = 'favorites'
              ..value = '["profit","dividend"]',
          ),
        );
      });
      await mount(tester);

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('2 pinned · everything runs on device'), findsOneWidget);
      // Pinned tools appear once — in the rail — not again in their section.
      expect(find.text('Profit & Loss'), findsOneWidget);
      expect(find.text('Dividend Reinvest'), findsOneWidget);
      expect(find.text('Start here'), findsNothing);
    },
    skip: !hasIsarCore,
  );
}
