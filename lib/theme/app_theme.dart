import 'package:flutter/material.dart';

// The app began as a replica of the open-source Needham Capital app, whose
// brand was green. The brand is now blue: one hue carries the primary and every
// neutral, so no surface keeps a cast from the old palette.
const ink = Color(0xff101828); // onSurface (light)
const muted = Color(0xff667085); // secondary text
const paper = Color(0xffffffff); // light page: white, blue is the accent
const accent = Color(0xff0b57d0); // brand blue (light primary)
const accentBright = Color(0xff8ab4f8); // brand blue (dark primary)
const card = Color(0xffffffff);
const divider = Color(0xffe1e7f0);

/// Up/down colors, light mode values used by the original app.
///
/// These stay green and red whatever the brand does: in a price list the color
/// is the meaning, so re-hueing one to match a blue primary would make a gain
/// and the brand read alike.
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

const String kAppName = 'Axight';

/// Tabular figures keep digit columns aligned, which is what makes a column of
/// prices or totals scannable. Apply to any number the user compares.
const List<FontFeature> tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

/// The spacing scale. Every inset and gap comes from here, so the vertical
/// rhythm stays a decision instead of the sum of whatever values each screen
/// happened to reach for.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// The horizontal inset every screen shares, so titles, cards and list rows
  /// all start on the same line down the page.
  static const double gutter = lg;

  /// Inner padding of a card or sheet.
  static const double card = lg;

  /// Bottom inset for a scrolling list that has to clear a floating action
  /// button, so the last row is never parked under it.
  static const double fabInset = 88;

  /// Horizontal inset of a card's contents.
  static const EdgeInsets cardContent = EdgeInsets.symmetric(
    horizontal: card,
    vertical: lg,
  );
}

/// The type ramp.
///
/// The Material ramp is tuned for reading apps; this one is tuned for a phone
/// sized list of prices. Two things follow from that and are settled here so no
/// screen has to settle them again: numbers carry tabular figures (harmless on
/// letters, the whole point on digits), and each role states its weight and
/// leading rather than leaning on the default and an override at the call site.
TextTheme _textTheme(ColorScheme scheme) {
  final primary = scheme.onSurface;
  final secondary = scheme.onSurfaceVariant;
  return TextTheme(
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.5,
      color: primary,
      fontFeatures: tabularFigures,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.2,
      color: primary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: primary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0,
      color: primary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
      color: primary,
      fontFeatures: tabularFigures,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
      color: primary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
      color: primary,
      fontFeatures: tabularFigures,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0.1,
      color: secondary,
      fontFeatures: tabularFigures,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.1,
      color: secondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.7,
      color: secondary,
    ),
  );
}

/// The one field shape the app uses: a filled box with a hairline that turns
/// blue while the field has focus. Stated once here so every field agrees, and
/// so a field on a white page still shows an edge.
OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: color, width: width),
    );

InputDecorationTheme _fieldTheme(ColorScheme scheme, Color fill) =>
    InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: _fieldBorder(scheme.outlineVariant),
      enabledBorder: _fieldBorder(scheme.outlineVariant),
      focusedBorder: _fieldBorder(scheme.primary, width: 1.5),
      errorBorder: _fieldBorder(scheme.error),
      focusedErrorBorder: _fieldBorder(scheme.error, width: 1.5),
    );

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xffd7e3ff),
    onPrimaryContainer: Color(0xff001a41),
    secondary: Color(0xff4a5c86),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xffdbe2f4),
    onSecondaryContainer: Color(0xff14213d),
    surface: Colors.white,
    onSurface: ink,
    // Lowest and Low are spelled out because a container left unspecified
    // collapses onto `surface`, which left the two lightest steps with no value
    // of their own: every field or dropdown asking for one got the page color.
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xfff4f7fb),
    surfaceContainer: Color(0xffeef2f8),
    surfaceContainerHigh: Color(0xffe8edf5),
    surfaceContainerHighest: Color(0xffe1e7f0),
    onSurfaceVariant: Color(0xff4a5568),
    outline: Color(0xff6b7688),
    // Used by anything the framework draws with a hairline of its own — chips,
    // for one — which on a white page wants to be a whisper, not the outline.
    outlineVariant: Color(0xffdbe2ee),
    error: Color(0xffba1a1a),
    onError: Colors.white,
  );
  final text = _textTheme(scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: paper,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: ink,
      titleTextStyle: text.titleLarge,
    ),
    // A white card on a white page has no edge of its own, so the card keeps
    // its shape with a hairline instead of relying on a tinted page behind it.
    cardTheme: const CardThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: divider),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 0.6,
      space: 0.6,
    ),
    inputDecorationTheme: _fieldTheme(scheme, Colors.white),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    // The tab bar is the last surface that would have stayed tinted: its
    // Material default is surfaceContainer, which is the one step off white.
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    // Sheets stay white too, which is what keeps a tinted field visible inside
    // one; on the default container colour the two would be the same white.
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

ThemeData buildDarkTheme() {
  const onSurfaceDark = Color(0xffe4e9f2);
  const scheme = ColorScheme.dark(
    primary: accentBright,
    onPrimary: Color(0xff002e69),
    primaryContainer: Color(0xff00458f),
    onPrimaryContainer: Color(0xffd7e3ff),
    secondary: Color(0xffb6c4e4),
    onSecondary: Color(0xff22304f),
    secondaryContainer: Color(0xff344566),
    onSecondaryContainer: Color(0xffdbe2f4),
    surface: Color(0xff0f1524),
    onSurface: onSurfaceDark,
    // Spelled out for the same reason as the light scheme: an unspecified
    // container collapses onto `surface`, so these steps would have had no
    // value of their own in the dark theme either.
    surfaceContainerLowest: Color(0xff0b111d),
    surfaceContainerLow: Color(0xff141b28),
    surfaceContainer: Color(0xff1a2434),
    surfaceContainerHigh: Color(0xff222e42),
    surfaceContainerHighest: Color(0xff2b3850),
    onSurfaceVariant: Color(0xffbfc9da),
    outline: Color(0xff8895aa),
    outlineVariant: Color(0xff3b475e),
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
  );
  final text = _textTheme(scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: const Color(0xff0f1524),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: onSurfaceDark,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xff17202f),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xff2b3850),
      thickness: 0.6,
      space: 0.6,
    ),
    // Dark fields fill with a step above the sheet they sit on, which is the
    // same relationship the white field has to a white sheet in light mode.
    inputDecorationTheme: _fieldTheme(scheme, scheme.surfaceContainerHigh),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentBright,
        foregroundColor: const Color(0xff002e69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
