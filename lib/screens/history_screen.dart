import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tools.dart';
import '../models/saved_record.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'calc_scaffold.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(savedRecordsProvider);
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        title: const Text('Saved Records'),
      ),
      body: records.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 140),
                Icon(Icons.bookmark_border_rounded,
                    size: 56, color: Color(0xffc3c9d4)),
                SizedBox(height: 14),
                Center(
                  child: Text(
                    'No saved records yet',
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                ),
                DisclaimerFooter(),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              itemCount: records.length + 1,
              itemBuilder: (context, index) {
                if (index == records.length) {
                  return const DisclaimerFooter();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecordCard(record: records[index]),
                );
              },
            ),
    );
  }
}

class _RecordCard extends ConsumerWidget {
  const _RecordCard({required this.record});

  final SavedRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = toolById(record.toolId);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tool.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(tool.icon, color: tool.color, size: 21),
        ),
        title: Text(
          record.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${record.toolName} · ${fmtDateTime(record.createdAt)}',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ),
        children: [
          if (record.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Note: ${record.note}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xff5c6673),
                  ),
                ),
              ),
            ),
          _JsonSection(title: 'Inputs', json: record.inputsJson),
          const SizedBox(height: 10),
          _JsonSection(title: 'Results', json: record.resultsJson),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            buildCalculatorScreen(tool, record: record),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Load'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xffed6a5a),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete "${record.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffed6a5a),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(savedRecordsProvider.notifier).delete(record.id);
    }
  }
}

class _JsonSection extends StatelessWidget {
  const _JsonSection({required this.title, required this.json});

  final String title;
  final String json;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff7f8fb),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in data.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
