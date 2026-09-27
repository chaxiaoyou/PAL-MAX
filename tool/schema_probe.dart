// Temporary diagnostic: reproduces the schema upgrade an existing install goes
// through when the new build adds collections to the same Isar database.
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/native/isar_core.dart';
import 'package:pjza/models/app_setting.dart';
import 'package:pjza/models/saved_record.dart';
import 'package:pjza/models/stored_alert.dart';
import 'package:pjza/models/stored_transaction.dart';

Future<void> main() async {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME'] ?? '.'}/.pub-cache';
  final coreLib = '$pubCache/hosted/pub.dev/'
      'isar_community_flutter_libs-3.3.2/macos/libisar.dylib';
  await initializeCoreBinary(libraries: {Abi.current(): coreLib});

  final dir = Directory.systemTemp.createTempSync('schema_probe');
  const name = 'probe';

  // 1. The database as an older install left it: only the legacy collections.
  final old = await Isar.open(
    [SavedRecordSchema, AppSettingSchema],
    directory: dir.path,
    name: name,
  );
  await old.writeTxn(() async {
    await old.appSettings.put(AppSetting()..key = 'theme'..value = 'dark');
  });
  await old.close();
  print('step 1: old schema created and closed');

  // 2. The new build opens the same file with two extra collections.
  try {
    final upgraded = await Isar.open(
      [
        SavedRecordSchema,
        AppSettingSchema,
        StoredTransactionSchema,
        StoredAlertSchema,
      ],
      directory: dir.path,
      name: name,
    );
    final settings = await upgraded.appSettings.where().findAll();
    print('step 2: reopened OK, legacy rows preserved: ${settings.length}');
    await upgraded.writeTxn(() async {
      await upgraded.storedTransactions.put(
        StoredTransaction()
          ..uid = 'x'
          ..symbol = 'WALMEX.MX'
          ..sideCode = 'buy'
          ..quantity = 1
          ..price = 1
          ..fees = 0
          ..executedAt = DateTime(2026)
          ..note = '',
      );
    });
    print('step 3: write to new collection OK');
    await upgraded.close();
  } catch (error, stackTrace) {
    print('STEP 2 FAILED: $error');
    print(stackTrace.toString().split('\n').take(6).join('\n'));
  }
}
