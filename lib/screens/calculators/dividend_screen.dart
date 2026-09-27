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

class DividendScreen extends ConsumerStatefulWidget {
  const DividendScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<DividendScreen> createState() => _DividendScreenState();
}

class _DividendScreenState extends ConsumerState<DividendScreen> {
  final _priceCtrl = TextEditingController();
  final _dividendCtrl = TextEditingController();
  final _sharesCtrl = TextEditingController();
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
    _dividendCtrl.text =
        fmtInput((data['dividend'] as num?)?.toDouble() ?? 0);
    _sharesCtrl.text = fmtInput((data['shares'] as num?)?.toDouble() ?? 0);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _dividendCtrl.dispose();
    _sharesCtrl.dispose();
    super.dispose();
  }

  DividendResult get _result => calcDividend(
        price: parseNum(_priceCtrl.text),
        dividendPerShare: parseNum(_dividendCtrl.text),
        shares: parseNum(_sharesCtrl.text),
      );

  Map<String, dynamic> _inputsJson() => {
        'price': parseNum(_priceCtrl.text),
        'dividend': parseNum(_dividendCtrl.text),
        'shares': parseNum(_sharesCtrl.text),
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultDividendYield: fmtPct(r.yieldPct),
      l10n.resultTotalDividend: fmtAmount(r.totalDividend),
      l10n.resultReinvestShares: fmtNum(r.extraShares),
      l10n.resultTotalSharesAfter: fmtNum(r.totalShares),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('dividend'),
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
    final tool = toolById('dividend');
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
              label: l10n.fieldAssetPrice,
              controller: _priceCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldDividendPerShare,
              controller: _dividendCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: l10n.fieldSharesHeld,
              suffix: l10n.suffixShares,
              controller: _sharesCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow(l10n.resultDividendYield, fmtPct(result.yieldPct)),
            ResultRow(l10n.resultTotalDividend, fmtAmount(result.totalDividend)),
            ResultRow(l10n.resultReinvestShares, fmtNum(result.extraShares)),
            ResultRow(
              l10n.resultTotalSharesAfter,
              fmtNum(result.totalShares),
            ),
          ],
        ),
      ],
    );
  }
}
