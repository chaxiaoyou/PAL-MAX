import 'package:isar_community/isar.dart';

part 'saved_record.g.dart';

@collection
class SavedRecord {
  Id id = Isar.autoIncrement;

  late String toolId;
  late String toolName;
  late String title;
  late String note;
  late String inputsJson;
  late String resultsJson;
  late DateTime createdAt;
}
