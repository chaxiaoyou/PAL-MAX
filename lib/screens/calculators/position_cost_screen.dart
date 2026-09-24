import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tools.dart';
import '../../models/saved_record.dart';
import '../../models/tool_definition.dart';
import '../../theme/app_theme.dart';
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
    final r = _result;
    return {
      'Total Position Value': fmtAmount(r.totalAmount),
      'Total Quantity': fmtNum(r.totalQty),
      'Average Cost': fmtAmount(r.avgCost),
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
        SnackBar(content: Text(asNew ? 'Saved as "${saved.title}"' : 'Saved "${saved.title}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('position');
    final result = _result;
    final tableRows = [
      for (final row in _rows)
        [
          fmtDate(row.date),
          row.isBuy ? 'Add' : 'Reduce',
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
          title: 'Add / Reduce Records',
          trailing: Text(
            '${_rows.length} records',
            style: const TextStyle(color: muted, fontSize: 12.5),
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
                label: const Text('Add Record'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResultCard(
          accent: tool.color,
          rows: [
            ResultRow('Total Position Value', fmtAmount(result.totalAmount)),
            ResultRow('Total Quantity', fmtNum(result.totalQty)),
            ResultRow('Average Cost', fmtAmount(result.avgCost)),
          ],
        ),
        if (tableRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          TableCard(
            title: 'Record Details',
            accent: tool.color,
            columns: ['Date', 'Side', 'Price', 'Qty', 'Amount'],
            rows: tableRows,
          ),
        ],
      ],
    );
  }

  Widget _buildRow(ToolDefinition tool, _PositionRow row) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffbfbfd),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.07)),
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
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 19, color: Color(0xffb3bac6)),
              ),
            ],
          ),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Add'),
                selected: row.isBuy,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: tool.color.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: row.isBuy ? tool.color : muted,
                ),
                onSelected: (_) => setState(() => row.isBuy = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Reduce'),
                selected: !row.isBuy,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: const Color(0xffed6a5a).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: !row.isBuy ? const Color(0xffed6a5a) : muted,
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
                  label: 'Price',
                  controller: row.priceCtrl,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberField(
                  label: 'Qty',
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
