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

class TargetPriceScreen extends ConsumerStatefulWidget {
  const TargetPriceScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<TargetPriceScreen> createState() =>
      _TargetPriceScreenState();
}

class _TargetPriceScreenState extends ConsumerState<TargetPriceScreen> {
  final _priceCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
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
    _priceCtrl.text = fmtInput((data['price'] as num?)?.toDouble() ?? 0);
    _rateCtrl.text = fmtInput((data['rate'] as num?)?.toDouble() ?? 0);
    _isLong = data['isLong'] == true;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  TargetPriceResult get _result => calcTargetPrice(
        isLong: _isLong,
        price: parseNum(_priceCtrl.text),
        ratePct: parseNum(_rateCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'isLong': _isLong,
        'price': parseNum(_priceCtrl.text),
        'rate': parseNum(_rateCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultTargetPrice: fmtAmount(r.target),
      l10n.resultExpectedChange: fmtSigned(r.change),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('target'),
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
    final tool = toolById('target');
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
                  label: Text(l10n.segmentLongUpside),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.segmentShortDownside),
                ),
              ],
              selected: {_isLong},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _isLong = selection.first),
            ),
            const SizedBox(height: 16),
            NumberField(
              label: l10n.fieldCurrentPrice,
              controller: _priceCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldExpectedReturn,
              suffix: '%',
              controller: _rateCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            LabeledSwitch(
              label: l10n.fieldQuickReturn,
              children: [
                for (final rate in ['5', '10', '20', '50'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QuickChip(
                      label: l10n.quickReturnPct(rate),
                      color: tool.color,
                      onTap: () {
                        _rateCtrl.text = rate;
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
            ResultRow(l10n.resultTargetPrice, fmtAmount(result.target)),
            ResultRow(l10n.resultExpectedChange, fmtSigned(result.change)),
          ],
        ),
      ],
    );
  }
}
