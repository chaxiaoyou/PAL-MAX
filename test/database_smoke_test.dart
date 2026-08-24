import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:isar_community/src/native/isar_core.dart';
import 'package:pal_max/models/app_setting.dart';
import 'package:pal_max/models/saved_record.dart';

void main() {
  // Host-only smoke test: locate the native library shipped with
  // isar_community_flutter_libs.
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME'] ?? '.'}/.pub-cache';
  final coreLib = '$pubCache/hosted/pub.dev/'
      'isar_community_flutter_libs-3.3.2/macos/libisar.dylib';

  test(
    'Isar save / query / delete records',
    () async {
      final dir = Directory.systemTemp.createTempSync('pal_max_test');
      await initializeCoreBinary(libraries: {Abi.current(): coreLib});
      final isar = await Isar.open(
        [SavedRecordSchema, AppSettingSchema],
        directory: dir.path,
        name: 'pal_max_test',
      );

      final record = SavedRecord()
        ..toolId = 'compound'
        ..toolName = 'Compound Interest'
        ..title = 'Test Record'
        ..note = ''
        ..inputsJson = '{"principal": 10000}'
        ..resultsJson = '{"Total Balance": "11,000.00"}'
        ..createdAt = DateTime(2026, 8, 24);

      await isar.writeTxn(() => isar.savedRecords.put(record));

      final all = await isar.savedRecords.where().findAll();
      expect(all.length, 1);
      expect(all.first.title, 'Test Record');

      final sorted =
          await isar.savedRecords.where().sortByCreatedAtDesc().findAll();
      expect(sorted.first.id, record.id);

      final setting = AppSetting()
        ..key = 'favorites'
        ..value = '["compound","roi"]';
      await isar.writeTxn(() => isar.appSettings.put(setting));
      final found =
          await isar.appSettings.filter().keyEqualTo('favorites').findFirst();
      expect(found, isNotNull);
      expect(found!.value, contains('roi'));

      await isar.writeTxn(() => isar.savedRecords.delete(record.id));
      expect(await isar.savedRecords.where().count(), 0);

      await isar.close();
      dir.deleteSync(recursive: true);
    },
    skip: !File(coreLib).existsSync()
        ? 'isar_community_flutter_libs native library not found; skipped (host-only smoke test)'
        : false,
  );
}
