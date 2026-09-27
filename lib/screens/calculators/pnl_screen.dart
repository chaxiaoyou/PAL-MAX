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

class PnlScreen extends ConsumerStatefulWidget {
  const PnlScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<PnlScreen> createState() => _PnlScreenState();
}

class _PnlScreenState extends ConsumerState<PnlScreen> {
  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  bool _isLong = true;
  SavedRecord? _record;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) _restore(widget.record!);
  }

  void _restore(SavedRecord record) {
    _record = record;
    final data = jsonDecode(record.inputsJson) as Map<String, dynamic>;
    _entryCtrl.text = fmtInput((data['entry'] as num?)?.toDouble() ?? 0);
    _exitCtrl.text = fmtInput((data['exit'] as num?)?.toDouble() ?? 0);
    _qtyCtrl.text = fmtInput((data['qty'] as num?)?.toDouble() ?? 0);
    _feeCtrl.text = fmtInput((data['feePct'] as num?)?.toDouble() ?? 0);
    _isLong = data['isLong'] == true;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _qtyCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  PnlResult get _result => calcPnl(
        isLong: _isLong,
        entry: parseNum(_entryCtrl.text),
        exit: parseNum(_exitCtrl.text),
        qty: parseNum(_qtyCtrl.text),
        feePct: parseNum(_feeCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'isLong': _isLong,
        'entry': parseNum(_entryCtrl.text),
        'exit': parseNum(_exitCtrl.text),
        'qty': parseNum(_qtyCtrl.text),
        'feePct': parseNum(_feeCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultPnl: fmtAmount(r.amount),
      l10n.resultReturn: fmtPct(r.returnPct),
      l10n.resultFees: fmtAmount(r.fee),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('profit'),
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
    final tool = toolById('profit');
    final result = _result;
    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: l10n.sectionTradeParameters,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.segmentLong)),
                ButtonSegment(value: false, label: Text(l10n.segmentShort)),
              ],
              selected: {_isLong},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _isLong = selection.first),
            ),
            const SizedBox(height: 16),
            NumberField(
              label: l10n.fieldEntryPrice,
              controller: _entryCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldExitPrice,
              controller: _exitCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldQuantity,
              suffix: l10n.suffixShares,
              controller: _qtyCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldFeeRate,
              suffix: '%',
              controller: _feeCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow(l10n.resultPnl, fmtAmount(result.amount),
                tone: ResultTone.gain),
            ResultRow(l10n.resultReturn, fmtPct(result.returnPct),
                tone: ResultTone.gain),
            ResultRow(l10n.resultFees, fmtAmount(result.fee)),
          ],
        ),
      ],
    );
  }
}
