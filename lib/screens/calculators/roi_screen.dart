import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
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
    final r = _result;
    return {
      'ROI': fmtPct(r.returnPct),
      'Net Profit': fmtAmount(r.profit),
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
        SnackBar(content: Text(asNew ? 'Saved as "${saved.title}"' : 'Saved "${saved.title}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('roi');
    final result = _result;
    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: 'Inputs',
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Return Amount')),
                ButtonSegment(value: false, label: Text('Final Value')),
              ],
              selected: {_incomeMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _incomeMode = selection.first),
            ),
            const SizedBox(height: 16),
            NumberField(
              label: 'Invested Cost',
              controller: _costCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: _incomeMode ? 'Return Amount' : 'Final Value',
              controller: _amountCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow('ROI', fmtPct(result.returnPct)),
            ResultRow('Net Profit', fmtAmount(result.profit)),
          ],
        ),
      ],
    );
  }
}
