import 'package:isar_community/isar.dart';

part 'app_setting.g.dart';

@collection
class AppSetting {
  Id id = Isar.autoIncrement;

  late String key;
  late String value;
}
