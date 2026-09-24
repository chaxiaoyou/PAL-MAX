import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../models/saved_record.dart';
import '../../utils/calculators.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../calc_scaffold.dart';

class AnnualReturnScreen extends ConsumerStatefulWidget {
  const AnnualReturnScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<AnnualReturnScreen> createState() =>
      _AnnualReturnScreenState();
}

class _AnnualReturnScreenState extends ConsumerState<AnnualReturnScreen> {
  final _principalCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
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
    _yearsCtrl.text = fmtInput((data['years'] as num?)?.toDouble() ?? 0);
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _targetCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  AnnualReturnResult get _result => calcAnnualReturn(
        principal: parseNum(_principalCtrl.text),
        target: parseNum(_targetCtrl.text),
        years: parseNum(_yearsCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'principal': parseNum(_principalCtrl.text),
        'target': parseNum(_targetCtrl.text),
        'years': parseNum(_yearsCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final r = _result;
    return {
      'Total Return': fmtPct(r.totalReturnPct),
      'Annualized Return': fmtPct(r.annualizedPct),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('rate'),
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
    final tool = toolById('rate');
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
              label: 'Term',
              suffix: 'years',
              controller: _yearsCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow('Total Return', fmtPct(result.totalReturnPct)),
            ResultRow('Annualized Return', fmtPct(result.annualizedPct)),
          ],
        ),
      ],
    );
  }
}
