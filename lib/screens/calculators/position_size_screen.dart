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

class PositionSizeScreen extends ConsumerStatefulWidget {
  const PositionSizeScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<PositionSizeScreen> createState() =>
      _PositionSizeScreenState();
}

class _PositionSizeScreenState extends ConsumerState<PositionSizeScreen> {
  final _entryCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  final _lossCtrl = TextEditingController();
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
    _stopCtrl.text = fmtInput((data['stop'] as num?)?.toDouble() ?? 0);
    _lossCtrl.text = fmtInput((data['maxLoss'] as num?)?.toDouble() ?? 0);
    _isLong = data['isLong'] == true;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _stopCtrl.dispose();
    _lossCtrl.dispose();
    super.dispose();
  }

  double get _entry => parseNum(_entryCtrl.text);

  PositionSizeResult get _result => calcPositionSize(
        entry: _entry,
        stop: parseNum(_stopCtrl.text),
        maxLoss: parseNum(_lossCtrl.text),
      );

  void _setStopByPct(double pct) {
    if (_entry <= 0) return;
    final stop = _isLong ? _entry * (1 - pct / 100) : _entry * (1 + pct / 100);
    _stopCtrl.text = fmtInput(stop);
    setState(() {});
  }

  Map<String, dynamic> _inputsJson() => {
        'isLong': _isLong,
        'entry': _entry,
        'stop': parseNum(_stopCtrl.text),
        'maxLoss': parseNum(_lossCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultMaxQuantity: fmtNum(r.maxQty),
      l10n.resultPositionValue: fmtAmount(r.totalValue),
      l10n.resultStopDistance: fmtPct(r.movePct),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('size'),
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
    final tool = toolById('size');
    final result = _result;
    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: l10n.sectionPositionSetup,
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
              label: l10n.fieldStopPrice,
              controller: _stopCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldMaxLoss,
              controller: _lossCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            LabeledSwitch(
              label: l10n.fieldQuickStop,
              children: [
                for (final pct in [3, 5, 10])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QuickChip(
                      label: l10n.labelStopPct('$pct'),
                      color: tool.color,
                      onTap: () => _setStopByPct(pct.toDouble()),
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
            ResultRow(l10n.resultMaxQuantity, fmtNum(result.maxQty)),
            ResultRow(l10n.resultPositionValue, fmtAmount(result.totalValue)),
            ResultRow(l10n.resultStopDistance, fmtPct(result.movePct)),
          ],
        ),
      ],
    );
  }
}
