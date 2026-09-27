import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n.dart';
import 'providers/providers.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

class PalMaxApp extends ConsumerWidget {
  const PalMaxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(
      appPrefsProvider.select((prefs) => prefs.theme),
    );
    final language = ref.watch(
      appPrefsProvider.select((prefs) => prefs.language),
    );
    final themeMode = switch (themePreference) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system => ThemeMode.system,
    };
    // null lets Flutter resolve the device locale; anything outside
    // supportedLocales falls back to the first entry (English).
    final locale = switch (language) {
      AppLanguage.system => null,
      AppLanguage.english => const Locale('en'),
      AppLanguage.spanish => const Locale('es'),
      AppLanguage.japanese => const Locale('ja'),
    };

    // Japanese is the app's default locale: Flutter falls back to the first
    // entry when the device locale is not supported, so it leads the list.
    // Device locales that do match (es-MX, en-US, …) keep their own language.
    final supportedLocales = <Locale>[
      const Locale('ja'),
      for (final supported in AppLocalizations.supportedLocales)
        if (supported.languageCode != 'ja') supported,
    ];

    final isDark = switch (themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final systemOverlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemOverlay,
        // Portfolio product shell. The previous `RootShell` (watchlist-first,
        // bottom tabs) is still in the tree untouched: swapping this one line
        // switches the app back.
        child: const AppShell(),
      ),
    );
  }
}
