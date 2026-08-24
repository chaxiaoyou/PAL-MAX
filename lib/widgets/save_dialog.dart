import 'package:flutter/material.dart';

class SaveRecordDraft {
  const SaveRecordDraft({required this.title, required this.note});

  final String title;
  final String note;
}

Future<SaveRecordDraft?> showSaveRecordDialog(
  BuildContext context, {
  required String initialTitle,
  String initialNote = '',
  required String actionLabel,
}) async {
  final titleCtrl = TextEditingController(text: initialTitle);
  final noteCtrl = TextEditingController(text: initialNote);
  String? errorText;

  final result = await showDialog<SaveRecordDraft>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(actionLabel == 'Save As' ? 'Save As Record' : 'Save Record'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Record name',
                    hintText: 'e.g. 2026 plan',
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    setState(() => errorText = 'Please enter a record name');
                    return;
                  }
                  Navigator.pop(
                    context,
                    SaveRecordDraft(
                      title: titleCtrl.text.trim(),
                      note: noteCtrl.text.trim(),
                    ),
                  );
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      );
    },
  );

  titleCtrl.dispose();
  noteCtrl.dispose();
  return result;
}
