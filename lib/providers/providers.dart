import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../models/app_setting.dart';
import '../models/saved_record.dart';

final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden in main()'),
);

// ---------- Saved records ----------

class SavedRecordsNotifier extends StateNotifier<List<SavedRecord>> {
  SavedRecordsNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _load() async {
    final records =
        await _db.savedRecords.where().sortByCreatedAtDesc().findAll();
    if (!mounted) return;
    state = records;
  }

  Future<SavedRecord> add(SavedRecord record) async {
    await _db.writeTxn(() => _db.savedRecords.put(record));
    await _load();
    return record;
  }

  Future<void> update(SavedRecord record) async {
    await _db.writeTxn(() => _db.savedRecords.put(record));
    await _load();
  }

  Future<void> delete(Id id) async {
    await _db.writeTxn(() => _db.savedRecords.delete(id));
    await _load();
  }
}

final savedRecordsProvider =
    StateNotifierProvider<SavedRecordsNotifier, List<SavedRecord>>(
  (ref) => SavedRecordsNotifier(ref),
);

// ---------- Favorites ----------

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _load() async {
    final setting =
        await _db.appSettings.filter().keyEqualTo('favorites').findFirst();
    if (!mounted || setting == null) return;
    try {
      final list = (jsonDecode(setting.value) as List).cast<String>();
      state = list.toSet();
    } catch (_) {
      // Ignore corrupted data
    }
  }

  Future<void> toggle(String toolId) async {
    final next = {...state};
    next.contains(toolId) ? next.remove(toolId) : next.add(toolId);
    state = next;
    final setting =
        await _db.appSettings.filter().keyEqualTo('favorites').findFirst();
    await _db.writeTxn(() async {
      final entry = setting ?? (AppSetting()..key = 'favorites');
      entry.value = jsonEncode(next.toList());
      await _db.appSettings.put(entry);
    });
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(ref),
);
