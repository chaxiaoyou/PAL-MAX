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
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultYearsNeeded: l10n.yearsCount(fmtNum(r.years)),
      l10n.resultApprox: l10n.yearsMonthsCount(r.yearInt, r.monthInt),
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
    final tool = toolById('time');
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
            NumberField(
              label: l10n.fieldPrincipal,
              controller: _principalCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldTargetAmount,
              controller: _targetCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldAnnualRate,
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
            ResultRow(
              l10n.resultYearsNeeded,
              l10n.yearsCount(fmtNum(result.years)),
            ),
            ResultRow(
              l10n.resultApprox,
              l10n.yearsMonthsCount(result.yearInt, result.monthInt),
            ),
          ],
        ),
      ],
    );
  }
}
