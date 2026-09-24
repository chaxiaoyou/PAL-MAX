import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needhamcapital/theme/app_theme.dart';

/// Relative luminance, the WCAG half of the contrast ratio.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final first = _luminance(a);
  final second = _luminance(b);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The brand is blue, and up/down stay green and red. Those two decisions are
/// easy to undo by accident while retouching the palette, which is what these
/// pin down. Exact hex values are left free on purpose, so the brand can be
/// re-tuned without rewriting the test.
void main() {
  test('the brand is blue in both brightnesses', () {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      final primary = theme.colorScheme.primary;
      expect(primary.b, greaterThan(primary.r));
      expect(primary.b, greaterThan(primary.g));
      expect(
        theme.colorScheme.primaryContainer.b,
        greaterThan(theme.colorScheme.primaryContainer.g),
      );
    }
    expect(buildLightTheme().brightness, Brightness.light);
    expect(buildDarkTheme().brightness, Brightness.dark);
  });

  test('up and down keep their own hues', () {
    for (final positive in [lightPositive, darkPositive]) {
      expect(positive.g, greaterThan(positive.r));
      expect(positive.g, greaterThan(positive.b));
    }
    for (final negative in [lightNegative, darkNegative]) {
      expect(negative.r, greaterThan(negative.g));
      expect(negative.r, greaterThan(negative.b));
    }
  });

  test('the text roles the app leans on keep their contrast', () {
    final light = buildLightTheme();
    // onSurfaceVariant carries nearly every secondary label in the app.
    expect(
      _contrast(light.colorScheme.onSurfaceVariant, paper),
      greaterThanOrEqualTo(4.5),
    );
    expect(_contrast(light.colorScheme.onSurface, paper), greaterThan(7));
    final dark = buildDarkTheme();
    expect(
      _contrast(dark.colorScheme.onSurfaceVariant, dark.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('the type ramp keeps one size per role', () {
    // The roles the app actually uses. Sizes are stated once here so a screen
    // never has to invent one, which is how the ramp drifted before.
    const expected = <String, double>{
      'displaySmall': 32,
      'headlineSmall': 22,
      'titleLarge': 20,
      'titleMedium': 16,
      'titleSmall': 14,
      'bodyMedium': 14,
      'bodySmall': 12,
      'labelSmall': 11,
    };
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      for (final entry in expected.entries) {
        final style = switch (entry.key) {
          'displaySmall' => theme.textTheme.displaySmall,
          'headlineSmall' => theme.textTheme.headlineSmall,
          'titleLarge' => theme.textTheme.titleLarge,
          'titleMedium' => theme.textTheme.titleMedium,
          'titleSmall' => theme.textTheme.titleSmall,
          'bodyMedium' => theme.textTheme.bodyMedium,
          'bodySmall' => theme.textTheme.bodySmall,
          _ => theme.textTheme.labelSmall,
        };
        expect(style?.fontSize, entry.value, reason: entry.key);
      }
    }
  });

  test('numbers are set in tabular figures', () {
    // Digits the user compares line up in a column; letters are unaffected, so
    // the roles that carry prices and totals carry the feature too.
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      for (final style in [
        theme.textTheme.displaySmall,
        theme.textTheme.titleSmall,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
      ]) {
        expect(
          style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    }
  });

  test('the spacing scale is 4-based', () {
    for (final value in [
      Space.xs,
      Space.sm,
      Space.md,
      Space.lg,
      Space.xl,
      Space.xxl,
      Space.xxxl,
    ]) {
      expect(value % 4, 0);
    }
    expect(Space.gutter, Space.lg);
  });

  test('the light theme is a white page with hairline edges', () {
    final light = buildLightTheme();
    expect(light.scaffoldBackgroundColor, Colors.white);
    // A white card on a white page has no edge of its own, so the card has to
    // draw one; without it every card on every screen disappears.
    final side = (light.cardTheme.shape as RoundedRectangleBorder?)?.side;
    expect(side, isNotNull);
    expect(side!.width, greaterThan(0));
    // The same goes for a field: white fill, so the edge has to be drawn.
    expect(light.inputDecorationTheme.fillColor, Colors.white);
    expect(light.inputDecorationTheme.enabledBorder, isA<OutlineInputBorder>());
    expect(
      (light.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
          .borderSide
          .width,
      greaterThan(0),
    );
    // The tab bar would otherwise keep the Material default's surfaceContainer
    // tint, the one surface left off white.
    expect(light.navigationBarTheme.backgroundColor, Colors.white);
    // The dark theme keeps its own surfaces.
    expect(buildDarkTheme().scaffoldBackgroundColor, isNot(Colors.white));
  });
}
