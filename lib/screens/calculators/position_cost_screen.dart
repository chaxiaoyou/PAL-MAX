import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../l10n/l10n.dart';
import '../../models/saved_record.dart';
import '../../models/tool_definition.dart';
import '../../utils/calculators.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../calc_scaffold.dart';

class _PositionRow {
  _PositionRow({required this.date})
      : priceCtrl = TextEditingController(),
        qtyCtrl = TextEditingController();

  DateTime date;
  bool isBuy = true;
  final TextEditingController priceCtrl;
  final TextEditingController qtyCtrl;

  void dispose() {
    priceCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class PositionCostScreen extends ConsumerStatefulWidget {
  const PositionCostScreen({super.key, this.record});

  final SavedRecord? record;

  @override
  ConsumerState<PositionCostScreen> createState() =>
      _PositionCostScreenState();
}

class _PositionCostScreenState extends ConsumerState<PositionCostScreen> {
  final List<_PositionRow> _rows = [];
  SavedRecord? _record;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _restore(widget.record!);
    } else {
      _rows.add(_PositionRow(date: DateTime.now()));
    }
  }

  void _restore(SavedRecord record) {
    _record = record;
    final data = jsonDecode(record.inputsJson) as Map<String, dynamic>;
    final list = (data['rows'] as List).cast<Map<String, dynamic>>();
    for (final item in list) {
      final row = _PositionRow(
        date: DateTime.tryParse(item['date'] as String? ?? '') ?? DateTime.now(),
      )
        ..isBuy = item['buy'] == true
        ..priceCtrl.text = fmtInput((item['price'] as num?)?.toDouble() ?? 0)
        ..qtyCtrl.text = fmtInput((item['qty'] as num?)?.toDouble() ?? 0);
      _rows.add(row);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  List<PositionRecord> get _records => [
        for (final row in _rows)
          PositionRecord(
            date: row.date,
            isBuy: row.isBuy,
            price: parseNum(row.priceCtrl.text),
            qty: parseNum(row.qtyCtrl.text),
          ),
      ];

  PositionCostResult get _result => calcPositionCost(_records);

  Future<void> _pickDate(_PositionRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => row.date = picked);
  }

  Map<String, dynamic> _inputsJson() => {
        'rows': [
          for (final row in _rows)
            {
              'date': row.date.toIso8601String(),
              'buy': row.isBuy,
              'price': parseNum(row.priceCtrl.text),
              'qty': parseNum(row.qtyCtrl.text),
            },
        ],
      };

  Map<String, dynamic> _resultsJson() {
    final l10n = context.l10n;
    final r = _result;
    return {
      l10n.resultTotalPositionValue: fmtAmount(r.totalAmount),
      l10n.resultTotalQuantity: fmtNum(r.totalQty),
      l10n.resultAverageCost: fmtAmount(r.avgCost),
    };
  }

  Future<void> _save({required bool asNew}) async {
    final saved = await persistRecord(
      context: context,
      ref: ref,
      tool: toolById('position'),
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
    final tool = toolById('position');
    final result = _result;
    final tableRows = [
      for (final row in _rows)
        [
          fmtDate(row.date),
          row.isBuy ? l10n.actionAdd : l10n.actionReduce,
          fmtAmount(parseNum(row.priceCtrl.text)),
          fmtNum(parseNum(row.qtyCtrl.text)),
          fmtAmount(parseNum(row.priceCtrl.text) * parseNum(row.qtyCtrl.text)),
        ],
    ];

    return CalculatorScaffold(
      tool: tool,
      loadedTitle: _record?.title,
      onSave: () => _save(asNew: false),
      onSaveAs: () => _save(asNew: true),
      children: [
        SectionCard(
          title: l10n.sectionAddReduceRecords,
          trailing: Text(
            l10n.recordsCount(_rows.length),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          children: [
            for (var i = 0; i < _rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildRow(tool, _rows[i]),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _rows.add(_PositionRow(date: DateTime.now()));
                }),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(l10n.actionAddRecord),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow(
              l10n.resultTotalPositionValue,
              fmtAmount(result.totalAmount),
            ),
            ResultRow(l10n.resultTotalQuantity, fmtNum(result.totalQty)),
            ResultRow(l10n.resultAverageCost, fmtAmount(result.avgCost)),
          ],
        ),
        if (tableRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          TableCard(
            title: l10n.tableRecordDetails,
            accent: tool.color,
            columns: [
              l10n.tableDate,
              l10n.tableSide,
              l10n.tablePrice,
              l10n.tableQty,
              l10n.tableAmount,
            ],
            rows: tableRows,
          ),
        ],
      ],
    );
  }

  Widget _buildRow(ToolDefinition tool, _PositionRow row) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _pickDate(row),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.calendar_today_rounded,
                    size: 15, color: tool.color),
                label: Text(
                  fmtDate(row.date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tool.color,
                  ),
                ),
              ),
              const Spacer(),
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
          Row(
            children: [
              ChoiceChip(
                label: Text(context.l10n.actionAdd),
                selected: row.isBuy,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: tool.color.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: row.isBuy ? tool.color : theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (_) => setState(() => row.isBuy = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(context.l10n.actionReduce),
                selected: !row.isBuy,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: danger.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: !row.isBuy ? danger : theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (_) => setState(() => row.isBuy = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: NumberField(
                  label: context.l10n.fieldPrice,
                  controller: row.priceCtrl,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberField(
                  label: context.l10n.fieldQty,
                  controller: row.qtyCtrl,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
