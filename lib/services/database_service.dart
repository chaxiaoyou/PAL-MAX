import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_setting.dart';
import '../models/holding.dart';
import '../models/price_alert.dart';
import '../models/saved_record.dart';
import '../models/transaction.dart';

Future<Isar> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      SavedRecordSchema,
      AppSettingSchema,
      HoldingSchema,
      TransactionSchema,
      PriceAlertSchema,
    ],
    directory: dir.path,
    name: 'needhamcapital',
  );
}
