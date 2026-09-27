import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../l10n/l10n.dart';
import '../../models/saved_record.dart';
import '../../utils/calculators.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../calc_scaffold.dart';

class RoiScreen extends ConsumerStatefulWidget {
  const RoiScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<RoiScreen> createState() => _RoiScreenState();
}

class _RoiScreenState extends ConsumerState<RoiScreen> {
  final _costCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _incomeMode = true;
  SavedRecord? _record;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) _restore(widget.record!);
  }

  void _restore(SavedRecord record) {
    _record = record;
    final data = jsonDecode(record.inputsJson) as Map<String, dynamic>;
    _costCtrl.text = fmtInput((data['cost'] as num?)?.toDouble() ?? 0);
    _amountCtrl.text = fmtInput((data['amount'] as num?)?.toDouble() ?? 0);
    _incomeMode = data['incomeMode'] == true;
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  RoiResult get _result => calcRoi(
        incomeMode: _incomeMode,
        cost: parseNum(_costCtrl.text),
        amount: parseNum(_amountCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'incomeMode': _incomeMode,
        'cost': parseNum(_costCtrl.text),
        'amount': parseNum(_amountCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultRoi: fmtPct(r.returnPct),
      l10n.resultNetProfit: fmtAmount(r.profit),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('roi'),
      current: _record,
      asNew: asNew,
      inputs: _inputsJson(),
      results: _resultsJson(),
    );
    if (saved != null && mounted) {
      setState(() => _record = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asNew
                ? context.l10n.recordSavedAs(saved.title)
                : context.l10n.recordSaved(saved.title),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tool = toolById('roi');
    final result = _result;
    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: l10n.historyInputs,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.segmentReturnAmount),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.segmentFinalValue),
                ),
              ],
              selected: {_incomeMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _incomeMode = selection.first),
            ),
            const SizedBox(height: 16),
            NumberField(
              label: l10n.fieldInvestedCost,
              controller: _costCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: _incomeMode
                  ? l10n.segmentReturnAmount
                  : l10n.segmentFinalValue,
              controller: _amountCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow(l10n.resultRoi, fmtPct(result.returnPct),
                tone: ResultTone.gain),
            ResultRow(l10n.resultNetProfit, fmtAmount(result.profit),
                tone: ResultTone.gain),
          ],
        ),
      ],
    );
  }
}
