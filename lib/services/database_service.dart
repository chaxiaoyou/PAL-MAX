import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_setting.dart';
import '../models/saved_record.dart';
import '../models/stored_alert.dart';
import '../models/stored_transaction.dart';

Future<Isar> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      SavedRecordSchema,
      AppSettingSchema,
      StoredTransactionSchema,
      StoredAlertSchema,
    ],
    directory: dir.path,
    name: 'pjza',
  );
}
