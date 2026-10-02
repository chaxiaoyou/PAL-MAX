import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'providers/providers.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// The app shell: theme, then straight into the transit page, which is what
/// decides between the native UI and a steered web page.
class PalMaxApp extends ConsumerWidget {
  const PalMaxApp({super.key, this.fetchAppConf});

  /// Passed through to [SplashScreen] so the startup check can be driven in
  /// tests without reaching the network.
  final FetchAppConf? fetchAppConf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(
      appPrefsProvider.select((prefs) => prefs.theme),
    );
    final themeMode = switch (themePreference) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system => ThemeMode.system,
    };

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
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemOverlay,
        child: SplashScreen(fetchAppConf: fetchAppConf),
      ),
    );
  }
}
