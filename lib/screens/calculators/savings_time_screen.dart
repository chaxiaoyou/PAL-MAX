import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../models/saved_record.dart';
import '../../utils/calculators.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../calc_scaffold.dart';

class SavingsTimeScreen extends ConsumerStatefulWidget {
  const SavingsTimeScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<SavingsTimeScreen> createState() =>
      _SavingsTimeScreenState();
}

class _SavingsTimeScreenState extends ConsumerState<SavingsTimeScreen> {
  final _principalCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  SavedRecord? _record;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) _restore(widget.record!);
  }

  void _restore(SavedRecord record) {
    _record = record;
    final data = jsonDecode(record.inputsJson) as Map<String, dynamic>;
    _principalCtrl.text =
        fmtInput((data['principal'] as num?)?.toDouble() ?? 0);
    _targetCtrl.text = fmtInput((data['target'] as num?)?.toDouble() ?? 0);
    _rateCtrl.text = fmtInput((data['rate'] as num?)?.toDouble() ?? 0);
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _targetCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  SavingsTimeResult get _result => calcSavingsTime(
        principal: parseNum(_principalCtrl.text),
        target: parseNum(_targetCtrl.text),
        annualRatePct: parseNum(_rateCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'principal': parseNum(_principalCtrl.text),
        'target': parseNum(_targetCtrl.text),
        'rate': parseNum(_rateCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final r = _result;
    return {
      'Years Needed': '${fmtNum(r.years)} years',
      'Approx.': '${r.yearInt} years ${r.monthInt} months',
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('time'),
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
    final tool = toolById('time');
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
            NumberField(
              label: 'Principal',
              controller: _principalCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Target Amount',
              controller: _targetCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Annual Rate',
              suffix: '%',
              controller: _rateCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow('Years Needed', '${fmtNum(result.years)} years'),
            ResultRow(
              'Approx.',
              '${result.yearInt} years ${result.monthInt} months',
            ),
          ],
        ),
      ],
    );
  }
}
