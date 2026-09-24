import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pjza/data/tools.dart';
import 'package:pjza/screens/calc_scaffold.dart';

void main() {
  group('Calculator catalogue', () {
    test('every tool id is unique', () {
      final ids = appTools.map((tool) => tool.id).toSet();
      expect(ids.length, appTools.length);
    });

    test('toolById resolves every entry', () {
      for (final tool in appTools) {
        expect(toolById(tool.id).title, tool.title);
      }
    });

    testWidgets('each tool builds its calculator screen', (tester) async {
      for (final tool in appTools) {
        await tester.pumpWidget(
          MaterialApp(home: buildCalculatorScreen(tool)),
        );
        await tester.pump();
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: '${tool.id} did not build a screen',
        );
        expect(
          find.text(tool.title),
          findsWidgets,
          reason: '${tool.id} did not show its title',
        );
      }
    });
  });
}
