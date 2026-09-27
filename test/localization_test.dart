import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pjza/data/tools.dart';
import 'package:pjza/l10n/app_localizations.dart';
import 'package:pjza/l10n/app_localizations_en.dart';
import 'package:pjza/l10n/app_localizations_es.dart';
import 'package:pjza/l10n/app_localizations_ja.dart';
import 'package:pjza/providers/providers.dart';
import 'package:pjza/screens/settings_screen.dart';
import 'package:pjza/screens/tools_screen.dart';
import 'package:pjza/theme/app_theme.dart';

import 'isar_harness.dart';

/// Every translation must cover the same keys as the template, otherwise a
/// screen silently falls back to English (or, with nullable-getter disabled,
/// generates a build failure nobody notices until a release build).
Set<String> _messageKeys(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return raw.keys.where((key) => !key.startsWith('@')).toSet();
}

/// Every shipped catalogue, discovered from disk so adding a language cannot
/// accidentally skip these checks.
List<String> _cataloguePaths() {
  final files = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => path.endsWith('.arb'))
      .toList()
    ..sort();
  return files;
}

void main() {
  group('ARB catalogues', () {
    test('the template is not empty', () {
      expect(_cataloguePaths(), isNotEmpty);
    });

    test('every catalogue covers exactly the English messages', () {
      final en = _messageKeys('lib/l10n/app_en.arb');

      for (final path in _cataloguePaths()) {
        if (path.endsWith('app_en.arb')) continue;
        final keys = _messageKeys(path);
        expect(keys.difference(en), isEmpty, reason: '$path has extra keys');
        expect(en.difference(keys), isEmpty, reason: '$path is missing keys');
      }
    });

    test('no message is left empty', () {
      for (final path in _cataloguePaths()) {
        final raw = jsonDecode(File(path).readAsStringSync())
            as Map<String, dynamic>;
        for (final entry in raw.entries) {
          if (entry.key.startsWith('@')) continue;
          expect(
            (entry.value as String).trim(),
            isNotEmpty,
            reason: '${entry.key} is empty in $path',
          );
        }
      }
    });
  });

  group('Localized copy', () {
    test('Spanish and English resolve differently', () {
      final en = AppLocalizationsEn();
      final es = AppLocalizationsEs();

      expect(en.navWatchlist, 'Watchlist');
      expect(es.navWatchlist, 'Mi lista');
      expect(en.toolCompoundTitle, 'Compound Interest');
      expect(es.toolCompoundTitle, 'Interés compuesto');
      expect(es.disclaimerFooter, contains('asesoría'));
    });

    test('placeholders survive translation', () {
      final es = AppLocalizationsEs();
      expect(es.minutesCount(15), contains('15'));
      expect(es.searchAddedToWatchlist('AAPL'), contains('AAPL'));
      expect(es.yearsMonthsCount(2, 3), '2 años 3 meses');
      expect(es.recordSavedAs('Mi plan'), contains('Mi plan'));

      final ja = AppLocalizationsJa();
      expect(ja.minutesCount(15), contains('15'));
      expect(ja.searchAddedToWatchlist('AAPL'), contains('AAPL'));
      expect(ja.yearsMonthsCount(2, 3), '2 年 3 か月');
      expect(ja.recordSavedAs('マイプラン'), contains('マイプラン'));
    });

    test('Japanese is a real translation, not a copy of English', () {
      final en = AppLocalizationsEn();
      final ja = AppLocalizationsJa();

      expect(ja.navPortfolio, 'ポートフォリオ');
      expect(ja.alertsTitle, '価格アラート');
      expect(ja.columnAverageCost, '取得単価');
      expect(ja.navPortfolio, isNot(en.navPortfolio));
      expect(ja.disclaimerFooter, isNot(en.disclaimerFooter));
    });
  });

  group('Localized screens', () {
    late Isar? isar;
    final hasIsarCore = isarCoreLibPath() != null;

    setUpAll(() async {
      isar = await openTestIsar('pjza_l10n_test');
    });

    tearDownAll(() async {
      await isar?.close();
    });

    Widget wrap(Widget home, Locale locale) => ProviderScope(
          overrides: [isarProvider.overrideWithValue(isar!)],
          child: MaterialApp(
            theme: buildLightTheme(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        );

    Future<void> mount(WidgetTester tester, Widget home, Locale locale) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(home, locale));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
    }

    testWidgets(
      'calculator catalogue renders in Spanish',
      (tester) async {
        await mount(tester, const ToolsScreen(), const Locale('es'));

        expect(find.text('Calculadoras'), findsOneWidget);
        expect(find.text('Empieza aquí'), findsOneWidget);
        expect(find.text('Inversión'), findsOneWidget);
        expect(find.text('${appTools.length} calculadoras'), findsOneWidget);
        expect(find.text('Interés compuesto'), findsOneWidget);
      },
      skip: !hasIsarCore,
    );

    testWidgets(
      'settings expose the language switch in Spanish',
      (tester) async {
        await mount(tester, const SettingsScreen(), const Locale('es'));

        expect(find.text('Ajustes'), findsOneWidget);
        expect(find.text('Idioma'), findsOneWidget);
        expect(find.text('Seguir al sistema'), findsNWidgets(2));
        expect(find.text('Apariencia'), findsOneWidget);
      },
      skip: !hasIsarCore,
    );

    testWidgets(
      'the portfolio product renders in Japanese',
      (tester) async {
        await mount(tester, const ToolsScreen(), const Locale('ja'));

        expect(find.text('計算ツール'), findsOneWidget);
        expect(find.text('まずはこちら'), findsOneWidget);
        expect(find.text('投資'), findsOneWidget);
        expect(find.text('複利計算'), findsOneWidget);
      },
      skip: !hasIsarCore,
    );
  });
}
