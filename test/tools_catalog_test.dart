import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pjza/data/tools.dart';
import 'package:pjza/l10n/app_localizations.dart';
import 'package:pjza/l10n/app_localizations_en.dart';
import 'package:pjza/screens/calc_scaffold.dart';

void main() {
  // Tests assert the English catalogue, so resolve titles with an explicit
  // English localizations instance rather than the ambient locale.
  final l10n = AppLocalizationsEn();

  group('Calculator catalogue', () {
    test('every tool id is unique', () {
      final ids = appTools.map((tool) => tool.id).toSet();
      expect(ids.length, appTools.length);
    });

    test('toolById resolves every entry', () {
      for (final tool in appTools) {
        expect(toolById(tool.id).id, tool.id);
        expect(toolTitle(l10n, tool.id), isNotEmpty);
        expect(toolSubtitle(l10n, tool.id), isNotEmpty);
      }
    });

    testWidgets('each tool builds its calculator screen', (tester) async {
      for (final tool in appTools) {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: buildCalculatorScreen(tool),
          ),
        );
        await tester.pump();
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: '${tool.id} did not build a screen',
        );
        expect(
          find.text(toolTitle(l10n, tool.id)),
          findsWidgets,
          reason: '${tool.id} did not show its title',
        );
      }
    });
  });
}
