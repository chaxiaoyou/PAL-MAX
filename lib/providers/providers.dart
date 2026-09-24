import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../models/app_setting.dart';
import '../models/saved_record.dart';
import '../services/yahoo_service.dart';

final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden in main()'),
);

// ---------- Saved calculator records ----------

/// Results saved from the calculator tools, newest first.
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

// ---------- Favorite tools ----------

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  static const _key = 'favorites';

  Future<void> _load() async {
    final raw = await _readSetting(_db, _key);
    if (!mounted || raw == null) return;
    try {
      state = (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      // Ignore corrupted data and keep the current selection.
    }
  }

  Future<void> toggle(String toolId) async {
    final next = {...state};
    next.contains(toolId) ? next.remove(toolId) : next.add(toolId);
    state = next;
    await _writeSetting(_db, _key, jsonEncode(next.toList()));
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(ref),
);

final yahooApiProvider = Provider<YahooFinanceApi>((ref) {
  final api = YahooFinanceApi();
  ref.onDispose(api.dispose);
  return api;
});

// ---------- Persistent key/value settings (Isar AppSetting) ----------

Future<String?> _readSetting(Isar db, String key) async {
  final entry = await db.appSettings.filter().keyEqualTo(key).findFirst();
  return entry?.value;
}

Future<void> _writeSetting(Isar db, String key, String value) async {
  final entry = await db.appSettings.filter().keyEqualTo(key).findFirst();
  await db.writeTxn(() async {
    final next = entry ?? (AppSetting()..key = key);
    next.value = value;
    await db.appSettings.put(next);
  });
}

// ---------- Watchlist ----------

const defaultWatchlist = <String>[
  '^GSPC',
  '^DJI',
  'GOOG',
  'AAPL',
  'MSFT',
];

const _watchlistKey = 'watchlist_symbols';

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _load() async {
    final raw = await _readSetting(_db, _watchlistKey);
    if (raw == null) {
      state = List.of(defaultWatchlist);
      await _writeSetting(
        _db,
        _watchlistKey,
        jsonEncode(defaultWatchlist),
      );
      return;
    }
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      state = list;
    } catch (_) {
      state = List.of(defaultWatchlist);
    }
  }

  Future<void> setSymbols(List<String> symbols) async {
    final cleaned = symbols
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    state = cleaned;
    await _writeSetting(_db, _watchlistKey, jsonEncode(cleaned));
  }

  Future<void> add(String symbol) async {
    final symbolTrimmed = symbol.trim();
    if (symbolTrimmed.isEmpty || state.contains(symbolTrimmed)) return;
    await setSymbols([...state, symbolTrimmed]);
  }

  Future<void> remove(String symbol) async {
    await setSymbols(state.where((s) => s != symbol).toList());
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final next = List.of(state);
    final item = next.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex -= 1;
    next.insert(newIndex.clamp(0, next.length), item);
    await setSymbols(next);
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<String>>(
  (ref) => WatchlistNotifier(ref),
);

// ---------- App preferences ----------

enum ThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const ThemePreference(this.storageValue);

  final String storageValue;

  static ThemePreference fromStorage(String? value) => switch (value) {
        'light' => ThemePreference.light,
        'dark' => ThemePreference.dark,
        _ => ThemePreference.system,
      };
}

class AppPrefs {
  const AppPrefs({
    this.theme = ThemePreference.system,
    this.refreshMinutes = 5,
    this.roundTwoDp = true,
    this.autoSort = false,
  });

  final ThemePreference theme;
  final int refreshMinutes;
  final bool roundTwoDp;
  final bool autoSort;

  AppPrefs copyWith({
    ThemePreference? theme,
    int? refreshMinutes,
    bool? roundTwoDp,
    bool? autoSort,
  }) {
    return AppPrefs(
      theme: theme ?? this.theme,
      refreshMinutes: refreshMinutes ?? this.refreshMinutes,
      roundTwoDp: roundTwoDp ?? this.roundTwoDp,
      autoSort: autoSort ?? this.autoSort,
    );
  }
}

class AppPrefsNotifier extends StateNotifier<AppPrefs> {
  AppPrefsNotifier(this._ref) : super(const AppPrefs()) {
    _load();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _load() async {
    final theme = ThemePreference.fromStorage(
      await _readSetting(_db, 'theme'),
    );
    final refreshRaw = await _readSetting(_db, 'refresh_minutes');
    final roundRaw = await _readSetting(_db, 'round_2dp');
    final autoRaw = await _readSetting(_db, 'auto_sort');
    state = AppPrefs(
      theme: theme,
      refreshMinutes: int.tryParse(refreshRaw ?? '') ?? 5,
      roundTwoDp: roundRaw != '0',
      autoSort: autoRaw == '1',
    );
  }

  Future<void> setTheme(ThemePreference value) async {
    state = state.copyWith(theme: value);
    await _writeSetting(_db, 'theme', value.storageValue);
  }

  Future<void> setRefreshMinutes(int value) async {
    state = state.copyWith(refreshMinutes: value);
    await _writeSetting(_db, 'refresh_minutes', '$value');
  }

  Future<void> setRoundTwoDp(bool value) async {
    state = state.copyWith(roundTwoDp: value);
    await _writeSetting(_db, 'round_2dp', value ? '1' : '0');
  }

  Future<void> setAutoSort(bool value) async {
    state = state.copyWith(autoSort: value);
    await _writeSetting(_db, 'auto_sort', value ? '1' : '0');
  }
}

final appPrefsProvider =
    StateNotifierProvider<AppPrefsNotifier, AppPrefs>(
  (ref) => AppPrefsNotifier(ref),
);
