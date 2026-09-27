import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

class SaveRecordDraft {
  const SaveRecordDraft({required this.title, required this.note});

  final String title;
  final String note;
}

Future<SaveRecordDraft?> showSaveRecordDialog(
  BuildContext context, {
  required String initialTitle,
  String initialNote = '',
  bool asNew = false,
}) async {
  final l10n = context.l10n;
  final actionLabel = asNew ? l10n.actionSaveAs : l10n.actionSave;
  final dialogTitle =
      asNew ? l10n.dialogSaveAsRecord : l10n.dialogSaveRecord;
  final titleCtrl = TextEditingController(text: initialTitle);
  final noteCtrl = TextEditingController(text: initialNote);
  String? errorText;

  final result = await showDialog<SaveRecordDraft>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.fieldRecordName,
                    hintText: l10n.fieldRecordNameHint,
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusControl),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.fieldRecordNote,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusControl),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    setState(() => errorText = l10n.errorRecordNameRequired);
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
