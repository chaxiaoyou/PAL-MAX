import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pjza/theme/app_theme.dart';

void main() {
  group('PJTZA Inc branding', () {
    test('app name is the new brand', () {
      expect(kAppName, 'PJTZA Inc');
    });

    test('light and dark themes share the blue brand color', () {
      final light = buildLightTheme();
      final dark = buildDarkTheme();
      expect(light.colorScheme.primary, accent);
      expect(dark.colorScheme.primary, accentBright);
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.scaffoldBackgroundColor, paper);
    });
  });

  group('Quote direction colors', () {
    testWidgets('resolve per brightness', (tester) async {
      Future<({Color up, Color down, Color flat})> resolve(ThemeData theme) async {
        late BuildContext captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(builder: (context) {
              captured = context;
              return const SizedBox();
            }),
          ),
        );
        // MaterialApp cross-fades theme changes, so let the animation finish
        // before reading the resolved colors.
        await tester.pumpAndSettle();
        return (
          up: changeColor(captured, QuoteDirection.up),
          down: changeColor(captured, QuoteDirection.down),
          flat: changeColor(captured, QuoteDirection.flat),
        );
      }

      final light = await resolve(buildLightTheme());
      expect(light.up, lightPositive);
      expect(light.down, lightNegative);
      expect(light.flat, buildLightTheme().colorScheme.onSurfaceVariant);

      final dark = await resolve(buildDarkTheme());
      expect(dark.up, darkPositive);
      expect(dark.down, darkNegative);
      expect(
        dark.flat,
        buildDarkTheme().colorScheme.onSurfaceVariant,
      );
    });
  });
}
