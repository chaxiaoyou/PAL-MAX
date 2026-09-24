import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
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
    final r = _result;
    return {
      'Total Balance': fmtAmount(r.total),
      'Total Interest': fmtAmount(r.totalInterest),
      'Total Return': fmtPct(r.totalReturnRate),
      'Total Invested': fmtAmount(r.totalInvested),
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
        SnackBar(content: Text(asNew ? 'Saved as "${saved.title}"' : 'Saved "${saved.title}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('compound');
    final result = _result;
    final rows = result.rows
        .map((row) => [
              'Year ${row.year}',
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
          title: 'Inputs',
          children: [
            NumberField(
              label: 'Initial Principal',
              controller: _principalCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Periodic Contribution',
              controller: _addCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            LabeledSwitch(
              label: 'Frequency',
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Monthly')),
                    ButtonSegment(value: false, label: Text('Yearly')),
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
              label: 'Annual Rate',
              suffix: '%',
              controller: _rateCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Term',
              suffix: 'years',
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
                      label: 'Rate $rate%',
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
                      label: '${term}y',
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
            ResultRow('Total Balance', fmtAmount(result.total)),
            ResultRow('Total Interest', fmtAmount(result.totalInterest)),
            ResultRow('Total Return', fmtPct(result.totalReturnRate)),
            ResultRow('Total Invested', fmtAmount(result.totalInvested)),
          ],
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          TableCard(
            title: 'Yearly Breakdown',
            accent: tool.color,
            columns: ['Year', 'Principal', 'Interest', 'Year Rate', 'Balance'],
            rows: rows,
          ),
        ],
      ],
    );
  }
}
