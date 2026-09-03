import 'package:flutter/material.dart';

// Palette used by the open-source Stocks Widget app (Material 3 green brand).
const ink = Color(0xff1a1c18); // onSurface (light)
const muted = Color(0xff6e6e6e); // secondary text
const paper = Color(0xfffcfdf6); // light background
const accent = Color(0xff006e08); // brand green (light primary)
const accentBright = Color(0xff5ce150); // brand green (dark primary)
const card = Color(0xffffffff);
const divider = Color(0xffe4e5df);

/// Up/down colors, light mode values used by the original app.
const lightPositive = Color(0xff009900);
const lightNegative = Color(0xffe55b5b);
const darkPositive = Color(0xffccff66);
const darkNegative = Color(0xffff6666);

/// Resolves the up/down color for the current brightness.
Color positiveColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? darkPositive
        : lightPositive;

Color negativeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? darkNegative
        : lightNegative;

enum QuoteDirection { up, down, flat }

Color changeColor(BuildContext context, QuoteDirection direction) {
  switch (direction) {
    case QuoteDirection.up:
      return positiveColor(context);
    case QuoteDirection.down:
      return negativeColor(context);
    case QuoteDirection.flat:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

const String kAppName = 'Stocks Widget';

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xff79ff6a),
    onPrimaryContainer: Color(0xff002201),
    secondary: Color(0xff9a4600),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xffffdbc9),
    onSecondaryContainer: Color(0xff321200),
    surface: Colors.white,
    onSurface: ink,
    surfaceContainerHighest: Color(0xffe4e5df),
    surfaceContainerHigh: Color(0xffeaebe5),
    surfaceContainer: Color(0xfff0f1eb),
    onSurfaceVariant: Color(0xff43493f),
    outline: Color(0xff73796e),
    error: Color(0xffba1a1a),
    onError: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: ink,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: const CardThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 0.6,
      space: 0.6,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: accentBright,
    onPrimary: Color(0xff003a02),
    primaryContainer: Color(0xff005304),
    onPrimaryContainer: Color(0xff79ff6a),
    secondary: Color(0xffffb68c),
    onSecondary: Color(0xff532200),
    surface: Color(0xff1a1c18),
    onSurface: Color(0xffe2e3dd),
    surfaceContainerHighest: Color(0xff333530),
    surfaceContainerHigh: Color(0xff282b26),
    surfaceContainer: Color(0xff1e201c),
    onSurfaceVariant: Color(0xffc3c8bc),
    outline: Color(0xff8d9387),
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xff1a1c18),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: Color(0xffe2e3dd),
      titleTextStyle: TextStyle(
        color: Color(0xffe2e3dd),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xff1d1d1d),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xff333530),
      thickness: 0.6,
      space: 0.6,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentBright,
        foregroundColor: const Color(0xff003a02),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
