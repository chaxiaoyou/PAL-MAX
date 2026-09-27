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

class CompoundInterestScreen extends ConsumerStatefulWidget {
  const CompoundInterestScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<CompoundInterestScreen> createState() =>
      _CompoundInterestScreenState();
}

class _CompoundInterestScreenState
    extends ConsumerState<CompoundInterestScreen> {
  final _principalCtrl = TextEditingController();
  final _addCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  bool _monthly = true;
  SavedRecord? _record;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) _restore(widget.record!);
  }

  void _restore(SavedRecord record) {
    _record = record;
    final data = jsonDecode(record.inputsJson) as Map<String, dynamic>;
    _principalCtrl.text = fmtInput((data['principal'] as num).toDouble());
    _addCtrl.text = fmtInput((data['add'] as num?)?.toDouble() ?? 0);
    _rateCtrl.text = fmtInput((data['rate'] as num?)?.toDouble() ?? 0);
    _termCtrl.text = fmtInput((data['term'] as num?)?.toDouble() ?? 0);
    _monthly = data['monthly'] == true;
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _addCtrl.dispose();
    _rateCtrl.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  CompoundResult get _result => calcCompound(
        principal: parseNum(_principalCtrl.text),
        contribution: parseNum(_addCtrl.text),
        monthly: _monthly,
        annualRatePct: parseNum(_rateCtrl.text),
        years: parseNum(_termCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'principal': parseNum(_principalCtrl.text),
        'add': parseNum(_addCtrl.text),
        'rate': parseNum(_rateCtrl.text),
        'term': parseNum(_termCtrl.text),
        'monthly': _monthly,
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultTotalBalance: fmtAmount(r.total),
      l10n.resultTotalInterest: fmtAmount(r.totalInterest),
      l10n.resultTotalReturn: fmtPct(r.totalReturnRate),
      l10n.resultTotalInvested: fmtAmount(r.totalInvested),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('compound'),
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
    final tool = toolById('compound');
    final result = _result;
    final rows = result.rows
        .map((row) => [
              l10n.yearLabel(row.year),
              fmtAmount(row.contributed),
              fmtAmount(row.interest),
              fmtPct(row.yearRate),
              fmtAmount(row.endTotal),
            ])
        .toList();

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
              label: l10n.fieldInitialPrincipal,
              controller: _principalCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldPeriodicContribution,
              controller: _addCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            LabeledSwitch(
              label: l10n.fieldFrequency,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.segmentMonthly),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.segmentYearly),
                    ),
                  ],
                  selected: {_monthly},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      setState(() => _monthly = selection.first),
                ),
              ],
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldAnnualRate,
              suffix: '%',
              controller: _rateCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldTerm,
              suffix: l10n.suffixYears,
              controller: _termCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final rate in ['3', '5', '8'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QuickChip(
                      label: l10n.quickRate(rate),
                      color: tool.color,
                      onTap: () {
                        _rateCtrl.text = rate;
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final term in ['1', '3', '5', '10'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QuickChip(
                      label: l10n.quickTermYears(term),
                      color: tool.color,
                      onTap: () {
                        _termCtrl.text = term;
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow(l10n.resultTotalBalance, fmtAmount(result.total)),
            ResultRow(l10n.resultTotalInterest, fmtAmount(result.totalInterest)),
            ResultRow(l10n.resultTotalReturn, fmtPct(result.totalReturnRate),
                tone: ResultTone.gain),
            ResultRow(l10n.resultTotalInvested, fmtAmount(result.totalInvested)),
          ],
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          TableCard(
            title: l10n.resultYearlyBreakdown,
            accent: tool.color,
            columns: [
              l10n.tableYear,
              l10n.tablePrincipal,
              l10n.tableInterest,
              l10n.tableYearRate,
              l10n.tableBalance,
            ],
            rows: rows,
          ),
        ],
      ],
    );
  }
}
