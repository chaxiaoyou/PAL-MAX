import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../models/saved_record.dart';
import '../../utils/calculators.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../calc_scaffold.dart';

class RiskRewardScreen extends ConsumerStatefulWidget {
  const RiskRewardScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<RiskRewardScreen> createState() => _RiskRewardScreenState();
}

class _RiskRewardScreenState extends ConsumerState<RiskRewardScreen> {
  final _entryCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _multiplierCtrl = TextEditingController(text: '1');
  final _marginCtrl = TextEditingController();
  bool _isLong = true;
  bool _futures = false;
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
    _targetCtrl.text = fmtInput((data['target'] as num?)?.toDouble() ?? 0);
    _qtyCtrl.text = fmtInput((data['qty'] as num?)?.toDouble() ?? 0);
    _multiplierCtrl.text =
        fmtInput((data['multiplier'] as num?)?.toDouble() ?? 1);
    _marginCtrl.text = fmtInput((data['marginPct'] as num?)?.toDouble() ?? 0);
    _isLong = data['isLong'] == true;
    _futures = data['futures'] == true;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _stopCtrl.dispose();
    _targetCtrl.dispose();
    _qtyCtrl.dispose();
    _multiplierCtrl.dispose();
    _marginCtrl.dispose();
    super.dispose();
  }

  double get _entry => parseNum(_entryCtrl.text);
  double get _stop => parseNum(_stopCtrl.text);

  RiskRewardResult get _result => calcRiskReward(
        isLong: _isLong,
        futures: _futures,
        entry: _entry,
        stop: _stop,
        target: parseNum(_targetCtrl.text),
        qty: parseNum(_qtyCtrl.text),
        multiplier: _futures ? parseNum(_multiplierCtrl.text) : 1,
        marginPct: _futures ? parseNum(_marginCtrl.text) : 0,
      );

  void _setStopByPct(double pct) {
    if (_entry <= 0) return;
    final stop = _isLong ? _entry * (1 - pct / 100) : _entry * (1 + pct / 100);
    _stopCtrl.text = fmtInput(stop);
    setState(() {});
  }

  void _setTargetByRatio(double ratio) {
    if (_entry <= 0 || _stop <= 0) return;
    final risk = (_entry - _stop).abs();
    final target = _isLong ? _entry + ratio * risk : _entry - ratio * risk;
    _targetCtrl.text = fmtInput(target);
    setState(() {});
  }

  Map<String, dynamic> _inputsJson() => {
        'isLong': _isLong,
        'futures': _futures,
        'entry': _entry,
        'stop': _stop,
        'target': parseNum(_targetCtrl.text),
        'qty': parseNum(_qtyCtrl.text),
        'multiplier': _futures ? parseNum(_multiplierCtrl.text) : 1,
        'marginPct': _futures ? parseNum(_marginCtrl.text) : 0,
      };

  Map<String, dynamic> _resultsJson() {
    final r = _result;
    return {
      'Risk / Reward': '${fmtNum(r.ratio)} : 1',
      'Target Profit': fmtAmount(r.targetProfit),
      'Expected Loss': fmtAmount(r.expectedLoss),
      if (r.marginRequired != null) 'Margin Required': fmtAmount(r.marginRequired!),
      if (r.returnOnMargin != null) 'Return on Margin': fmtPct(r.returnOnMargin!),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('risk'),
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
    final tool = toolById('risk');
    final result = _result;
    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: 'Trade Setup',
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Long')),
                      ButtonSegment(value: false, label: Text('Short')),
                    ],
                    selected: {_isLong},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _isLong = selection.first),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Spot')),
                      ButtonSegment(value: true, label: Text('Futures')),
                    ],
                    selected: {_futures},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _futures = selection.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NumberField(
              label: 'Entry Price',
              controller: _entryCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Stop Price',
              controller: _stopCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Target Price',
              controller: _targetCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Quantity',
              suffix: 'units',
              controller: _qtyCtrl,
              onChanged: (_) => setState(() {}),
            ),
            if (_futures) ...[
              const SizedBox(height: 14),
              NumberField(
                label: 'Contract Multiplier',
                suffix: '/ point',
                controller: _multiplierCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              NumberField(
                label: 'Margin',
                suffix: '%',
                controller: _marginCtrl,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            LabeledSwitch(
              label: 'Quick Stop %',
              children: [
                for (final pct in [3, 5, 10])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QuickChip(
                      label: 'Stop $pct%',
                      color: tool.color,
                      onTap: () => _setStopByPct(pct.toDouble()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LabeledSwitch(
              label: 'Quick R/R',
              children: [
                for (final ratio in [1, 2, 3])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QuickChip(
                      label: 'R/R 1:$ratio',
                      color: tool.color,
                      onTap: () => _setTargetByRatio(ratio.toDouble()),
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
            ResultRow('Risk / Reward', '${fmtNum(result.ratio)} : 1'),
            ResultRow('Target Profit', fmtAmount(result.targetProfit)),
            ResultRow('Expected Loss', fmtAmount(result.expectedLoss)),
            if (result.marginRequired != null)
              ResultRow('Margin Required', fmtAmount(result.marginRequired!)),
            if (result.returnOnMargin != null)
              ResultRow('Return on Margin', fmtPct(result.returnOnMargin!)),
          ],
        ),
      ],
    );
  }
}
