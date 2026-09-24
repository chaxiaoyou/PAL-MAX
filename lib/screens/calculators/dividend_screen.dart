import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
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
    final r = _result;
    return {
      'Dividend Yield': fmtPct(r.yieldPct),
      'Total Dividend': fmtAmount(r.totalDividend),
      'Reinvest Shares': fmtNum(r.extraShares),
      'Total Shares After': fmtNum(r.totalShares),
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
        SnackBar(content: Text(asNew ? 'Saved as "${saved.title}"' : 'Saved "${saved.title}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('dividend');
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
              label: 'Asset Price',
              controller: _priceCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Dividend per Share',
              controller: _dividendCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            NumberField(
              label: 'Shares Held',
              suffix: 'shares',
              controller: _sharesCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow('Dividend Yield', fmtPct(result.yieldPct)),
            ResultRow('Total Dividend', fmtAmount(result.totalDividend)),
            ResultRow('Reinvest Shares', fmtNum(result.extraShares)),
            ResultRow('Total Shares After', fmtNum(result.totalShares)),
          ],
        ),
      ],
    );
  }
}
