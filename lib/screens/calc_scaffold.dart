import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tools.dart';
import '../models/saved_record.dart';
import '../models/tool_definition.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/save_dialog.dart';

import 'calculators/annual_return_screen.dart';
import 'calculators/asset_allocation_screen.dart';
import 'calculators/compound_interest_screen.dart';
import 'calculators/dividend_screen.dart';
import 'calculators/pnl_screen.dart';
import 'calculators/position_cost_screen.dart';
import 'calculators/position_size_screen.dart';
import 'calculators/risk_reward_screen.dart';
import 'calculators/roi_screen.dart';
import 'calculators/savings_time_screen.dart';
import 'calculators/target_price_screen.dart';

class CalculatorScaffold extends StatelessWidget {
  const CalculatorScaffold({
    super.key,
    required this.tool,
    required this.children,
    required this.onSave,
    required this.onSaveAs,
    this.loadedTitle,
  });

  final ToolDefinition tool;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final String? loadedTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(title: Text(tool.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            if (loadedTitle != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        size: 17, color: tool.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Loaded: $loadedTitle',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tool.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...children,
            const DisclaimerFooter(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 19),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSaveAs,
                    icon: const Icon(Icons.save_alt_rounded, size: 19),
                    label: const Text('Save As'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared save / save-as flow. Returns the persisted record, or null if cancelled.
Future<SavedRecord?> persistRecord({
  required BuildContext context,
  required WidgetRef ref,
  required ToolDefinition tool,
  required SavedRecord? current,
  required bool asNew,
  required Map<String, dynamic> inputs,
  required Map<String, dynamic> results,
}) async {
  final draft = await showSaveRecordDialog(
    context,
    initialTitle: current?.title ?? tool.title,
    initialNote: current?.note ?? '',
    actionLabel: asNew ? 'Save As' : 'Save',
  );
  if (draft == null) return null;

  final record = SavedRecord()
    ..toolId = tool.id
    ..toolName = tool.title
    ..title = draft.title
    ..note = draft.note
    ..inputsJson = jsonEncode(inputs)
    ..resultsJson = jsonEncode(results)
    ..createdAt = DateTime.now();

  final notifier = ref.read(savedRecordsProvider.notifier);
  if (!asNew && current != null) {
    record.id = current.id;
    record.createdAt = current.createdAt;
    await notifier.update(record);
  } else {
    await notifier.add(record);
  }
  return record;
}

/// Creates the calculator screen for the given tool (optionally loading a record).
Widget buildCalculatorScreen(ToolDefinition tool, {SavedRecord? record}) {
  switch (tool.id) {
    case 'compound':
      return CompoundInterestScreen(record: record);
    case 'risk':
      return RiskRewardScreen(record: record);
    case 'position':
      return PositionCostScreen(record: record);
    case 'size':
      return PositionSizeScreen(record: record);
    case 'dividend':
      return DividendScreen(record: record);
    case 'allocation':
      return AssetAllocationScreen(record: record);
    case 'profit':
      return PnlScreen(record: record);
    case 'target':
      return TargetPriceScreen(record: record);
    case 'rate':
      return AnnualReturnScreen(record: record);
    case 'time':
      return SavingsTimeScreen(record: record);
    case 'roi':
      return RoiScreen(record: record);
    default:
      return buildCalculatorScreen(toolById('compound'));
  }
}
