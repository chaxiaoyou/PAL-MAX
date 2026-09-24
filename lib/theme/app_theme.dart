import 'package:flutter/material.dart';

/// PJT ZA brand palette, tuned to the launcher icon (deep royal blue).
///
/// The palette stays deliberately small: a blue brand color, a soft neutral
/// canvas and one accent per quote direction, so watchlist cards and the
/// calculator tools keep the same visual rhythm.
const ink = Color(0xff101828); // onSurface (light)
const muted = Color(0xff667085); // secondary text (light)
const paper = Color(0xfff4f6fb); // light canvas
const card = Color(0xffffffff); // light card surface
const divider = Color(0xffe5e8f0); // hairline (light)
const accent = Color(0xff0737bf); // brand blue (light primary)
const accentBright = Color(0xff8fb0ff); // brand blue (dark primary)

/// Surfaces used by the calculator result panel, identical in both themes so
/// the panel keeps its "printed" look on a light or dark canvas.
const resultFill = Color(0xff0b1c47); // deep navy panel
const resultOn = Color(0xffffffff);

/// Fallback accent for widgets that accept an optional accent color.
const defaultAccent = accent;

/// Up/down colors for quote changes.
const lightPositive = Color(0xff0e9f6e);
const lightNegative = Color(0xffe5484d);
const darkPositive = Color(0xff4ade80);
const darkNegative = Color(0xffff7a7a);

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

const String kAppName = 'PJT ZA';
const String kAppTagline = 'Invest & trade, with confidence.';

const _radiusCard = 18.0;
const _radiusControl = 14.0;

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xffdbe4ff),
    onPrimaryContainer: Color(0xff001551),
    secondary: Color(0xff4a5b8c),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xffdde3f7),
    onSecondaryContainer: Color(0xff0b1c47),
    surface: card,
    onSurface: ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xfff8f9fd),
    surfaceContainer: Color(0xffeff2f9),
    surfaceContainerHigh: Color(0xffe9edf6),
    surfaceContainerHighest: Color(0xffe2e7f2),
    onSurfaceVariant: Color(0xff4a5568),
    outline: Color(0xff98a2b3),
    outlineVariant: divider,
    error: Color(0xffd92d20),
    onError: Colors.white,
  );
  return _baseTheme(scheme: scheme, canvas: paper, onCanvas: ink);
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: accentBright,
    onPrimary: Color(0xff00246e),
    primaryContainer: Color(0xff0737bf),
    onPrimaryContainer: Color(0xffdbe4ff),
    secondary: Color(0xffb8c4e8),
    onSecondary: Color(0xff22315c),
    secondaryContainer: Color(0xff2a3a68),
    onSecondaryContainer: Color(0xffdde3f7),
    surface: Color(0xff141b2b),
    onSurface: Color(0xffe6eaf2),
    surfaceContainerLowest: Color(0xff0b1220),
    surfaceContainerLow: Color(0xff111828),
    surfaceContainer: Color(0xff1a2233),
    surfaceContainerHigh: Color(0xff20293c),
    surfaceContainerHighest: Color(0xff283248),
    onSurfaceVariant: Color(0xffa7b0c4),
    outline: Color(0xff5b657a),
    outlineVariant: Color(0xff2c3547),
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
  );
  return _baseTheme(
    scheme: scheme,
    canvas: const Color(0xff0b1220),
    onCanvas: const Color(0xffe6eaf2),
  );
}

ThemeData _baseTheme({
  required ColorScheme scheme,
  required Color canvas,
  required Color onCanvas,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: onCanvas,
      titleTextStyle: TextStyle(
        color: onCanvas,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radiusCard)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.8,
      space: 0.8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.primary,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(11)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusControl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusControl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusControl),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusControl),
        borderSide: BorderSide.none,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.onSurfaceVariant,
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide.none,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
