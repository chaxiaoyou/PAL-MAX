import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:isar_community/src/native/isar_core.dart';
import 'package:pal_max/app.dart';
import 'package:pal_max/models/app_setting.dart';
import 'package:pal_max/models/saved_record.dart';
import 'package:pal_max/providers/providers.dart';

void main() {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME'] ?? '.'}/.pub-cache';
  final coreLib = '$pubCache/hosted/pub.dev/'
      'isar_community_flutter_libs-3.3.2/macos/libisar.dylib';

  testWidgets(
    'home renders, opens a calculator, real-time calculation',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('pal_max_app_test');

      // Real async database initialization must run inside tester.runAsync
      final isar = (await tester.runAsync<Isar>(() async {
        await initializeCoreBinary(libraries: {Abi.current(): coreLib});
        return Isar.open(
          [SavedRecordSchema, AppSettingSchema],
          directory: dir.path,
          name: 'pal_max_app_test',
        );
      }))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [isarProvider.overrideWithValue(isar)],
          child: PalMaxApp(fetchAppConf: () async => null),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Home title and tool cards
      expect(find.text('PAL MAX'), findsOneWidget);
      expect(find.text('Compound Interest'), findsOneWidget);

      // Tap a card to open the calculator
      await tester.ensureVisible(find.text('Compound Interest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compound Interest'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save As'), findsOneWidget);
      expect(find.text('Inputs'), findsOneWidget);

      // Enter principal, result refreshes in real time (thousands separators)
      await tester.enterText(find.byType(TextField).first, '10000');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('10,000.00'), findsWidgets);

      // Disclaimer at the bottom of the page
      await tester.drag(find.byType(ListView).first, const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(
        find.text(
            'This tool is for demonstration only and does not constitute investment advice.'),
        findsOneWidget,
      );

      // Note: the Isar instance is released when the test process exits;
      // close() is intentionally not called here to avoid hanging on
      // queries still pending in the FakeAsync zone.
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {
        // The database file may still be in use; ignore cleanup failures
      }
    },
    skip: !File(coreLib).existsSync(),
  );
}
