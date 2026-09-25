import 'package:flutter/material.dart';

/// PJTZA Inc brand palette, tuned to the launcher icon (deep royal blue).
///
/// The tone is deliberately cool: every neutral carries a little of the brand
/// hue, so the canvas, dividers and text read as one navy system instead of
/// generic grey. The palette stays small — one brand color, one canvas and one
/// accent per quote direction — so watchlist cards and calculator tools keep
/// the same rhythm.
const ink = Color(0xff0d1627); // onSurface (light)
const muted = Color(0xff55617a); // secondary text (light)
const paper = Color(0xffeef1f8); // light canvas
const card = Color(0xffffffff); // light card surface
const divider = Color(0xffe0e5f0); // hairline (light)
const accent = Color(0xff003cd8); // brand blue (light primary)
const accentBright = Color(0xff8aa8ff); // brand blue (dark primary)

/// Surfaces used by the calculator result panel, identical in both themes so
/// the panel keeps its "printed" look on a light or dark canvas.
const resultFill = Color(0xff0c1c46); // deep navy panel
const resultOn = Color(0xffffffff);

/// Fallback accent for widgets that accept an optional accent color.
const defaultAccent = accent;

/// Up/down colors for quote changes. The light variants are deliberately deep:
/// change text is small and bold on white, so it has to clear 4.5:1 on its own
/// tinted badge rather than only look vivid.
const lightPositive = Color(0xff0a7a52);
const lightNegative = Color(0xffc62b31);
const darkPositive = Color(0xff4ade80);
const darkNegative = Color(0xffff7a7a);

/// Spacing scale (4pt base). Screens compose from these instead of ad-hoc
/// numbers so gaps between sections stay on the same rhythm.
const double kSpace1 = 4;
const double kSpace2 = 8;
const double kSpace3 = 12;
const double kSpace4 = 16;
const double kSpace5 = 20;
const double kSpace6 = 24;

/// Screen gutter and the inset used by every list / card surface.
const double kGutter = kSpace4;

/// Corner radii: cards are softer than controls.
const double kRadiusCard = 18;
const double kRadiusControl = 14;

/// Tabular figures keep prices, percentages and statistics on a fixed grid so
/// digits line up column-wise in the watchlist and the stats card.
const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

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

const String kAppName = 'PJTZA Inc';
const String kAppTagline = 'Invest & trade, with confidence.';

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xffdbe4ff),
    onPrimaryContainer: Color(0xff001449),
    secondary: Color(0xff46557f),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xffdde4f8),
    onSecondaryContainer: Color(0xff0a1738),
    surface: card,
    onSurface: ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xfff7f9fd),
    surfaceContainer: Color(0xffeaeff8),
    surfaceContainerHigh: Color(0xffe3e9f5),
    surfaceContainerHighest: Color(0xffdbe2f0),
    onSurfaceVariant: muted,
    outline: Color(0xff7c879e),
    outlineVariant: divider,
    error: Color(0xffd02f28),
    onError: Colors.white,
  );
  return _baseTheme(scheme: scheme, canvas: paper, onCanvas: ink);
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: accentBright,
    onPrimary: Color(0xff001a5e),
    primaryContainer: Color(0xff003cd8),
    onPrimaryContainer: Color(0xffdbe4ff),
    secondary: Color(0xffb6c2e6),
    onSecondary: Color(0xff1d2b52),
    secondaryContainer: Color(0xff26355f),
    onSecondaryContainer: Color(0xffdde4f8),
    surface: Color(0xff101a2b),
    onSurface: Color(0xffe7ebf5),
    surfaceContainerLowest: Color(0xff080f1c),
    surfaceContainerLow: Color(0xff0c1421),
    surfaceContainer: Color(0xff141e30),
    surfaceContainerHigh: Color(0xff1b2639),
    surfaceContainerHighest: Color(0xff232f45),
    onSurfaceVariant: Color(0xff9ba6bf),
    outline: Color(0xff5a657d),
    outlineVariant: Color(0xff26314a),
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
  );
  return _baseTheme(
    scheme: scheme,
    canvas: const Color(0xff070c16),
    onCanvas: const Color(0xffe7ebf5),
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
      // A hairline instead of a shadow: cards stay crisp on the tinted canvas
      // and dark mode never ends up with muddy grey halos.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          borderRadius: BorderRadius.circular(kRadiusControl),
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
          borderRadius: BorderRadius.circular(kRadiusControl),
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
        borderRadius: BorderRadius.circular(kRadiusControl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusControl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusControl),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusControl),
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
