import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../models/saved_record.dart';
import '../../models/tool_definition.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../calc_scaffold.dart';

class _AssetRow {
  _AssetRow()
      : nameCtrl = TextEditingController(),
        amountCtrl = TextEditingController(),
        pctCtrl = TextEditingController();

  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController pctCtrl;

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    pctCtrl.dispose();
  }
}

class AssetAllocationScreen extends ConsumerStatefulWidget {
  const AssetAllocationScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<AssetAllocationScreen> createState() =>
      _AssetAllocationScreenState();
}

class _AssetAllocationScreenState extends ConsumerState<AssetAllocationScreen> {
  final _totalCtrl = TextEditingController();
  final List<_AssetRow> _rows = [];
  SavedRecord? _record;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _restore(widget.record!);
    } else {
      for (var i = 0; i < 3; i++) {
        _rows.add(_AssetRow());
      }
    }
  }

  void _restore(SavedRecord record) {
    _record = record;
    final data = jsonDecode(record.inputsJson) as Map<String, dynamic>;
    _totalCtrl.text = fmtInput((data['total'] as num?)?.toDouble() ?? 0);
    final list = (data['rows'] as List).cast<Map<String, dynamic>>();
    for (final item in list) {
      final row = _AssetRow()
        ..nameCtrl.text = (item['name'] as String?) ?? ''
        ..amountCtrl.text =
            fmtInput((item['amount'] as num?)?.toDouble() ?? 0)
        ..pctCtrl.text = fmtInput((item['pct'] as num?)?.toDouble() ?? 0);
      _rows.add(row);
    }
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _total => parseNum(_totalCtrl.text);

  double _rowAmount(_AssetRow row) => parseNum(row.amountCtrl.text);

  double get _sumAmount =>
      _rows.fold(0.0, (sum, row) => sum + _rowAmount(row));

  double get _sumPct =>
      _rows.fold(0.0, (sum, row) => sum + parseNum(row.pctCtrl.text));

  void _onAmountChanged(_AssetRow row) {
    setState(() {
      if (_total > 0) {
        row.pctCtrl.text =
            fmtInput(_rowAmount(row) / _total * 100);
      }
    });
  }

  void _onPctChanged(_AssetRow row) {
    setState(() {
      row.amountCtrl.text =
          fmtInput(_total * parseNum(row.pctCtrl.text) / 100);
    });
  }

  Map<String, dynamic> _inputsJson() => {
        'total': _total,
        'rows': [
          for (final row in _rows)
            {
              'name': row.nameCtrl.text,
              'amount': _rowAmount(row),
              'pct': parseNum(row.pctCtrl.text),
            },
        ],
      };

  Map<String, dynamic> _resultsJson() => {
        'Allocated Amount': fmtAmount(_sumAmount),
        'Allocated %': fmtPct(_sumPct),
      };

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('allocation'),
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
    final tool = toolById('allocation');
    final remaining = _total - _sumAmount;
    final pctDiff = 100 - _sumPct;
    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: 'Total Assets',
          children: [
            NumberField(
              label: 'Total Assets',
              controller: _totalCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Allocations',
          trailing: Text(
            '${_rows.length} items',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          children: [
            for (var i = 0; i < _rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _buildRow(tool, _rows[i]),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _rows.add(_AssetRow())),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Add Asset'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow('Allocated Amount', fmtAmount(_sumAmount)),
            ResultRow('Allocated %', fmtPct(_sumPct)),
            ResultRow(
              'Remaining',
              remaining >= 0
                  ? fmtAmount(remaining)
                  : '-${fmtAmount(-remaining)}',
            ),
            ResultRow(
              '% Difference',
              pctDiff >= 0
                  ? fmtPct(pctDiff)
                  : '-${fmtPct(-pctDiff)}',
            ),
          ],
        ),
        if ((remaining - 0.005).abs() > 0.005 || (pctDiff - 0.005).abs() > 0.005)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xffe49a32)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    remaining > 0.005
                        ? '${fmtAmount(remaining)} not yet allocated'
                        : remaining < -0.005
                            ? 'Allocation exceeds total assets by ${fmtAmount(-remaining)}'
                            : 'Allocation is not 100% (missing ${fmtPct(pctDiff.abs())})',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRow(ToolDefinition tool, _AssetRow row) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.nameCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Asset name',
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _rows.length > 1
                    ? () => setState(() {
                          final removed = _rows.removeAt(_rows.indexOf(row));
                          removed.dispose();
                        })
                    : null,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: NumberField(
                  label: 'Amount',
                  controller: row.amountCtrl,
                  onChanged: (_) => _onAmountChanged(row),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberField(
                  label: 'Percent',
                  suffix: '%',
                  controller: row.pctCtrl,
                  onChanged: (_) => _onPctChanged(row),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
