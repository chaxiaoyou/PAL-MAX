import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../models/app_setting.dart';
import '../models/dividend.dart';
import '../models/dividend_income.dart';
import '../models/holding.dart';
import '../models/position_ledger.dart';
import '../models/portfolio_math.dart';
import '../models/price_alert.dart';
import '../models/quote.dart';
import '../models/transaction.dart';
import '../services/alert_notifier.dart';
import '../services/background_alerts.dart';
import '../services/yahoo_service.dart';

final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden in main()'),
);

final yahooApiProvider = Provider<YahooFinanceApi>((ref) {
  final api = YahooFinanceApi();
  ref.onDispose(api.dispose);
  return api;
});

// ---------- Quote board ----------

/// One place that fetches quotes for the whole app.
///
/// The watchlist and the portfolio each declare the symbols they care about;
/// the board fetches their union, so a symbol that appears in both is one
/// request instead of two. It also owns the refresh schedule, which used to be
/// a separate timer inside every screen.
class QuoteBoardState {
  const QuoteBoardState({
    this.quotes = const {},
    this.fetching = false,
    this.error,
    this.lastFetch,
  });

  final Map<String, Quote> quotes;
  final bool fetching;
  final String? error;
  final DateTime? lastFetch;
}

class QuoteBoard extends StateNotifier<QuoteBoardState> {
  QuoteBoard(this._ref) : super(const QuoteBoardState()) {
    _reschedule(_ref.read(appPrefsProvider).refreshMinutes);
    _ref.listen<int>(
      appPrefsProvider.select((prefs) => prefs.refreshMinutes),
      (_, minutes) => _reschedule(minutes),
    );
  }

  final Ref _ref;

  /// Symbols per source (`watchlist`, `portfolio`, …), in registration order.
  final Map<String, List<String>> _sources = {};
  Timer? _timer;
  Future<void>? _inFlight;
  bool _refreshAgain = false;

  /// Every registered symbol, deduplicated, sources first-come-first-served.
  List<String> get _wanted {
    final seen = <String>{};
    return [
      for (final symbols in _sources.values)
        for (final symbol in symbols)
          if (seen.add(symbol)) symbol,
    ];
  }

  /// Declares the symbols [source] cares about. Returns true when that added a
  /// symbol the board has no price for, i.e. fetching is worthwhile.
  bool register(String source, List<String> symbols) {
    final previous = _sources[source];
    if (previous != null && listEquals(previous, symbols)) return false;
    _sources[source] = List.of(symbols);
    _pruneQuotes();
    return _wanted.any((symbol) => !state.quotes.containsKey(symbol));
  }

  /// Drops quotes for symbols nobody is watching any more, so removing a
  /// symbol does not leave its price behind for the rest of the session.
  void _pruneQuotes() {
    final wanted = _wanted.toSet();
    final kept = {
      for (final entry in state.quotes.entries)
        if (wanted.contains(entry.key)) entry.key: entry.value,
    };
    if (kept.length == state.quotes.length) return;
    state = QuoteBoardState(
      quotes: kept,
      fetching: state.fetching,
      error: state.error,
      lastFetch: state.lastFetch,
    );
  }

  void _reschedule(int minutes) {
    _timer?.cancel();
    _timer = minutes <= 0
        ? null
        : Timer.periodic(Duration(minutes: minutes), (_) => refresh());
  }

  /// Fetches every registered symbol. Callers that arrive while a request is
  /// in flight share it, and one more fetch runs right after so symbols
  /// registered mid-request are not left unpriced.
  Future<void> refresh() {
    final pending = _inFlight;
    if (pending != null) {
      _refreshAgain = true;
      return pending;
    }
    late final Future<void> future;
    future = _run().whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  Future<void> _run() async {
    await _fetchOnce();
    while (_refreshAgain) {
      _refreshAgain = false;
      await _fetchOnce();
    }
  }

  Future<void> _fetchOnce() async {
    final wanted = _wanted;
    if (wanted.isEmpty) {
      state = QuoteBoardState(quotes: state.quotes, lastFetch: DateTime.now());
      return;
    }
    state = QuoteBoardState(
      quotes: state.quotes,
      fetching: true,
      lastFetch: state.lastFetch,
    );
    try {
      final quotes = await _ref.read(yahooApiProvider).fetchQuotes(wanted);
      state = QuoteBoardState(
        quotes: {for (final quote in quotes) quote.symbol: quote},
        lastFetch: DateTime.now(),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('quote fetch failed: $error\n$stackTrace');
      }
      // Keep the last successful quotes. They are not passed off as live: the
      // fetch time is on screen and the error is reported. Blanking every
      // value on a dropped connection would be worse for no gain in honesty.
      state = QuoteBoardState(
        quotes: state.quotes,
        error: _messageFor(error),
        lastFetch: state.lastFetch,
      );
    }
  }

  String _messageFor(Object error) {
    if (error is YahooFinanceException) return error.message;
    return 'Unable to refresh quotes. Check your connection and try again.';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quoteBoardProvider =
    StateNotifierProvider<QuoteBoard, QuoteBoardState>(
  (ref) => QuoteBoard(ref),
);

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

class WatchlistState {
  const WatchlistState({this.symbols = const [], this.loaded = false});

  final List<String> symbols;

  /// False until the stored list has been read, so the UI can tell an empty
  /// watchlist apart from one that has not loaded yet.
  final bool loaded;

  bool contains(String symbol) => symbols.contains(symbol);
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  WatchlistNotifier(this._ref) : super(const WatchlistState()) {
    _load();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _load() async {
    final raw = await _readSetting(_db, _watchlistKey);
    if (raw == null) {
      await _publish(defaultWatchlist);
      await _writeSetting(
        _db,
        _watchlistKey,
        jsonEncode(defaultWatchlist),
      );
      return;
    }
    List<String> symbols;
    try {
      symbols = (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      symbols = List.of(defaultWatchlist);
    }
    await _publish(symbols);
  }

  Future<void> setSymbols(List<String> newSymbols) async {
    final cleaned = newSymbols
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    await _publish(cleaned);
    await _writeSetting(_db, _watchlistKey, jsonEncode(cleaned));
  }

  /// Publishes the list and tells the quote board what to fetch. A fetch only
  /// starts when the board has no price for one of the new symbols.
  Future<void> _publish(List<String> newSymbols) async {
    state = WatchlistState(symbols: newSymbols, loaded: true);
    final board = _ref.read(quoteBoardProvider.notifier);
    if (board.register('watchlist', newSymbols)) {
      await board.refresh();
    }
  }

  Future<void> add(String symbol) async {
    final symbolTrimmed = symbol.trim();
    if (symbolTrimmed.isEmpty || state.contains(symbolTrimmed)) return;
    await setSymbols([...state.symbols, symbolTrimmed]);
  }

  Future<void> remove(String symbol) async {
    await setSymbols(state.symbols.where((s) => s != symbol).toList());
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.symbols.length) return;
    final next = List.of(state.symbols);
    final item = next.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex -= 1;
    next.insert(newIndex.clamp(0, next.length), item);
    await setSymbols(next);
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, WatchlistState>(
  (ref) => WatchlistNotifier(ref),
);

/// Quotes for the watchlist, in the order the user arranged it. Symbols the
/// board has no price for are simply absent, so the grid shows what is priced
/// rather than a row of placeholders.
final watchlistQuotesProvider = Provider<List<Quote>>((ref) {
  final symbols = ref.watch(watchlistProvider).symbols;
  final quotes = ref.watch(quoteBoardProvider).quotes;
  return [
    for (final symbol in symbols)
      if (quotes[symbol] != null) quotes[symbol]!,
  ];
});

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

// ---------- Portfolio ----------

/// Everything the portfolio tab needs: the stored positions, the latest quotes
/// for them, and the request state. [summary] derives market value and P/L, so
/// the UI never has to do portfolio math itself.
class PortfolioState {
  const PortfolioState({
    this.holdings = const [],
    this.loading = true,
  });

  final List<Holding> holdings;

  /// False until the stored positions have been read.
  final bool loading;
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  PortfolioNotifier(this._ref) : super(const PortfolioState()) {
    _reload();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _reload() async {
    final rows = _dedupeBySymbol(await _db.holdings.where().findAll());
    state = PortfolioState(holdings: rows, loading: false);
    final board = _ref.read(quoteBoardProvider.notifier);
    if (board.register('portfolio', [for (final row in rows) row.symbol])) {
      await board.refresh();
    }
  }

  /// Inserts or replaces the position for [draft]'s symbol. Name and currency
  /// come from a quote the board already holds, so a symbol that is also on the
  /// watchlist self-corrects instead of being typed by hand.
  Future<void> upsert(HoldingDraft draft) async {
    final quote = _ref.read(quoteBoardProvider).quotes[draft.symbol];
    final existing = await _db.holdings
        .filter()
        .symbolEqualTo(draft.symbol)
        .findFirst();
    final now = DateTime.now();
    final row = (existing ?? Holding())
      ..symbol = draft.symbol
      ..name = (quote != null && quote.name.isNotEmpty) ? quote.name : draft.name
      ..shares = draft.shares
      ..costPerShare = draft.costPerShare
      ..currency = quote?.currency ?? draft.currency
      ..createdAt = existing?.createdAt ?? now
      ..updatedAt = now;
    await _db.writeTxn(() => _db.holdings.put(row));
    await _reload();
  }

  Future<void> remove(String symbol) async {
    await _db.writeTxn(
      () => _db.holdings.filter().symbolEqualTo(symbol).deleteAll(),
    );
    await _reload();
  }

  /// Keeps one row per symbol even if a duplicate ever reaches the database,
  /// so a position can never be counted twice in the totals.
  List<Holding> _dedupeBySymbol(List<Holding> rows) {
    final seen = <String>{};
    return [
      for (final row in rows)
        if (seen.add(row.symbol)) row,
    ];
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>(
  (ref) => PortfolioNotifier(ref),
);

/// Positions priced with whatever the quote board currently holds, plus the
/// per-currency totals. Derived on demand, never stored.
final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final holdings = ref.watch(portfolioProvider).holdings;
  final quotes = ref.watch(quoteBoardProvider).quotes;
  final ledgers = ref.watch(ledgersProvider);
  return PortfolioSummary.from(holdings, quotes, ledgers: ledgers);
});

// ---------- Transactions ----------

/// The whole trade ledger, oldest first.
class TransactionsState {
  const TransactionsState({this.transactions = const [], this.loading = true});

  final List<Transaction> transactions;
  final bool loading;
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  TransactionsNotifier(this._ref) : super(const TransactionsState()) {
    _reload();
  }

  final Ref _ref;

  Isar get _db => _ref.read(isarProvider);

  Future<void> _reload() async {
    final rows = await _db.transactions.where().findAll();
    rows.sort((a, b) {
      final byDate = a.tradedAt.compareTo(b.tradedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    state = TransactionsState(transactions: rows, loading: false);
  }

  /// Adds or replaces a trade. [existing] is the row being edited, so its id —
  /// and therefore its place in same-day ordering — is preserved.
  Future<void> save(TransactionDraft draft, {Transaction? existing}) async {
    final row = (existing ?? Transaction())
      ..symbol = draft.symbol
      ..kind = draft.kind.storageValue
      ..shares = draft.shares
      ..pricePerShare = draft.pricePerShare
      ..fee = draft.fee
      ..tradedAt = draft.tradedAt
      ..currency = draft.currency
      ..note = draft.note;
    await _db.writeTxn(() => _db.transactions.put(row));
    await _reload();
  }

  Future<void> remove(Transaction transaction) async {
    await _db.writeTxn(() => _db.transactions.delete(transaction.id));
    await _reload();
  }

  /// Turns a hand-entered position into a ledger by writing a single opening
  /// buy, so later buys and sells have something to be measured against.
  Future<void> openLedgerFor(Holding holding) async {
    await save(
      TransactionDraft(
        symbol: holding.symbol,
        kind: TransactionKind.buy,
        shares: holding.shares,
        pricePerShare: holding.costPerShare,
        fee: 0,
        tradedAt: DateTime.now(),
        currency: holding.currency,
        note: 'Opening balance',
      ),
    );
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>(
  (ref) => TransactionsNotifier(ref),
);

/// Transactions grouped by symbol and reduced to what is actually held.
final ledgersProvider = Provider<Map<String, PositionLedger>>((ref) {
  final transactions = ref.watch(transactionsProvider).transactions;
  return PositionLedger.allFrom(transactions);
});

// ---------- Dividends ----------

/// Dividend history per symbol.
///
/// Fetched once per symbol and kept for the session: payments change quarterly,
/// so they deliberately do not ride the quote refresh loop.
class DividendState {
  const DividendState({
    this.payments = const {},
    this.loading = false,
    this.failed = const {},
  });

  final Map<String, List<DividendPayment>> payments;
  final bool loading;

  /// Symbols whose history could not be fetched. Remembered so a retry is
  /// explicit instead of a request every time the holdings change.
  final Set<String> failed;
}

class DividendNotifier extends StateNotifier<DividendState> {
  DividendNotifier(this._ref) : super(const DividendState()) {
    _ref.listen<PortfolioState>(
      portfolioProvider,
      (_, next) => _load(next.holdings),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  List<Holding> _wanted = const [];
  Future<void>? _inFlight;
  bool _again = false;

  /// Records what the portfolio holds now and fetches anything new. Callers
  /// that arrive during a fetch are served by one more pass afterwards.
  Future<void> _load(List<Holding> holdings) {
    _wanted = holdings;
    final pending = _inFlight;
    if (pending != null) {
      _again = true;
      return pending;
    }
    late final Future<void> future;
    future = _run().whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  Future<void> _run() async {
    await _pass();
    while (_again) {
      _again = false;
      await _pass();
    }
  }

  /// One symbol at a time: the chart endpoint takes a single symbol, and
  /// serialising keeps a large portfolio from bursting it.
  Future<void> _pass() async {
    final missing = [
      for (final holding in _wanted)
        if (!state.payments.containsKey(holding.symbol) &&
            !state.failed.contains(holding.symbol))
          holding.symbol,
    ];
    if (missing.isEmpty) return;

    state = DividendState(
      payments: state.payments,
      loading: true,
      failed: state.failed,
    );
    final payments = Map<String, List<DividendPayment>>.of(state.payments);
    final failed = Set<String>.of(state.failed);
    for (final symbol in missing) {
      try {
        payments[symbol] =
            await _ref.read(yahooApiProvider).fetchDividends(symbol);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('dividend fetch failed for $symbol: $error\n$stackTrace');
        }
        failed.add(symbol);
      }
      if (!mounted) return;
    }
    if (!mounted) return;
    state = DividendState(payments: payments, failed: failed);
  }

  /// Retries the symbols that failed and refetches nothing else.
  Future<void> retryFailed() async {
    if (state.failed.isEmpty) return;
    state = DividendState(payments: state.payments);
    await _load(_ref.read(portfolioProvider).holdings);
  }
}

final dividendProvider =
    StateNotifierProvider<DividendNotifier, DividendState>(
  (ref) => DividendNotifier(ref),
);

/// Dividend cash for the current holdings, bucketed by currency the same way
/// market value is.
final dividendSummaryProvider = Provider<DividendSummary>((ref) {
  final portfolio = ref.watch(portfolioSummaryProvider);
  final dividends = ref.watch(dividendProvider);
  final ledgers = ref.watch(ledgersProvider);
  return DividendSummary.from(
    portfolio: portfolio,
    payments: dividends.payments,
    ledgers: ledgers,
  );
});

// ---------- Price alerts ----------

final alertNotifierProvider = Provider<AlertNotifier>(
  (ref) => PlatformAlertNotifier(),
);

class AlertsState {
  const AlertsState({
    this.alerts = const [],
    this.loading = true,
    this.notificationsAllowed = true,
    this.backgroundReady = true,
  });

  final List<PriceAlert> alerts;
  final bool loading;

  /// False once the platform has told us it will not deliver notifications.
  final bool notificationsAllowed;

  /// False when Android refused to register the periodic check, which would
  /// otherwise leave the user believing alerts keep running when the app is
  /// closed.
  final bool backgroundReady;

  int get enabledCount {
    var count = 0;
    for (final alert in alerts) {
      if (alert.enabled) count++;
    }
    return count;
  }
}

/// Owns the alert rules and fires them.
///
/// It listens to the quote board rather than running its own timer, so an alert
/// is evaluated exactly when a price arrives — and only while the app is
/// running, which the UI states plainly.
class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier(this._ref) : super(const AlertsState()) {
    _start();
    _ref.listen<QuoteBoardState>(quoteBoardProvider, (_, next) {
      _check(next.quotes);
    });
  }

  final Ref _ref;
  Future<void>? _checking;
  bool _synced = false;

  Isar get _db => _ref.read(isarProvider);

  /// Loads the rules, hands Android what it needs to run the periodic check,
  /// and folds in whatever that check recorded while the app was closed.
  ///
  /// The order matters: merging before the first evaluation is what stops the
  /// app from re-announcing a crossing the background job already reported.
  Future<void> _start() async {
    await _reload();
    await _registerBackgroundJob();
    await _mergeNativeSides();
    _synced = true;
    await _pushToNative();
    await _check(_ref.read(quoteBoardProvider).quotes);
  }

  Future<void> _registerBackgroundJob() async {
    final handle = AlertRuleCodec.callbackHandle();
    if (handle == null) return;
    try {
      await AlertRuleCodec.channel().invokeMethod<void>(
        'setCallbackHandle',
        {'handle': handle},
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('alert background registration failed: $error\n$stackTrace');
      }
    }
  }

  /// Copies the sides recorded by the background job into the database.
  Future<void> _mergeNativeSides() async {
    final List<PriceAlert> native;
    try {
      native = AlertRuleCodec.decode(
        await AlertRuleCodec.channel().invokeMethod<String>('readRules'),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('alert state read failed: $error\n$stackTrace');
      }
      return;
    }
    if (native.isEmpty) return;

    final byId = {for (final rule in native) rule.id: rule};
    final changed = <PriceAlert>[];
    for (final alert in state.alerts) {
      final match = byId[alert.id];
      if (match == null) continue;
      if (match.lastAbove == alert.lastAbove &&
          match.triggeredAt == alert.triggeredAt) {
        continue;
      }
      alert
        ..lastAbove = match.lastAbove
        ..triggeredAt = match.triggeredAt
        ..updatedAt = DateTime.now();
      changed.add(alert);
    }
    if (changed.isEmpty) return;
    await _db.writeTxn(() => _db.priceAlerts.putAll(changed));
    await _reload();
  }

  /// Hands the current rules to Android, which stores them for the periodic job
  /// and only schedules that job while something is enabled.
  Future<void> _pushToNative() async {
    var ready = false;
    try {
      // The native side answers whether Android will actually run the periodic
      // check; the app reports that rather than assuming it.
      ready = await AlertRuleCodec.channel().invokeMethod<bool>('syncRules', {
            'rules': AlertRuleCodec.encode(state.alerts),
            'hasEnabled': state.enabledCount > 0,
          }) ??
          false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('alert sync failed: $error\n$stackTrace');
      }
    }
    if (!mounted) return;
    state = AlertsState(
      alerts: state.alerts,
      loading: false,
      notificationsAllowed: state.notificationsAllowed,
      backgroundReady: ready,
    );
  }

  Future<void> _reload() async {
    final rows = await _db.priceAlerts.where().findAll();
    rows.sort((a, b) {
      final bySymbol = a.symbol.compareTo(b.symbol);
      return bySymbol != 0 ? bySymbol : a.id.compareTo(b.id);
    });
    state = AlertsState(
      alerts: rows,
      loading: false,
      notificationsAllowed: state.notificationsAllowed,
      backgroundReady: state.backgroundReady,
    );
  }

  /// Asks the platform whether it will deliver notifications, without
  /// prompting. Safe to call while a screen builds.
  Future<void> refreshPermission() async {
    final allowed = await _ref.read(alertNotifierProvider).notificationsAllowed();
    if (!mounted) return;
    state = AlertsState(
      alerts: state.alerts,
      loading: false,
      notificationsAllowed: allowed,
    );
  }

  /// Prompts for permission. Returns false when notifications stay blocked.
  Future<bool> requestPermission() async {
    final allowed = await _ref.read(alertNotifierProvider).requestPermission();
    if (!mounted) return allowed;
    state = AlertsState(
      alerts: state.alerts,
      loading: false,
      notificationsAllowed: allowed,
    );
    return allowed;
  }

  Future<void> save(PriceAlertDraft draft, {PriceAlert? existing}) async {
    final now = DateTime.now();
    // Read the old level before the row is mutated: `row` *is* `existing` when
    // editing, so comparing them afterwards would always find them equal.
    final previousThreshold = existing?.threshold;
    final previousDirection = existing?.direction;
    final row = (existing ?? PriceAlert())
      ..symbol = draft.symbol
      ..name = draft.name
      ..direction = draft.direction.storageValue
      ..threshold = draft.threshold
      ..currency = draft.currency
      ..createdAt = existing?.createdAt ?? now
      ..updatedAt = now;
    // A new or edited level has to be re-armed: keeping the old side would
    // decide the next crossing against a threshold that no longer exists.
    if (existing == null ||
        previousThreshold != row.threshold ||
        previousDirection != row.direction) {
      row.lastAbove = null;
    }
    await _db.writeTxn(() => _db.priceAlerts.put(row));
    await _reload();
    await _pushToNative();
  }

  Future<void> setEnabled(PriceAlert alert, bool enabled) async {
    alert
      ..enabled = enabled
      ..updatedAt = DateTime.now()
      // Re-arming on enable: whatever happened while it was off is not an
      // event the user asked to hear about.
      ..lastAbove = enabled ? null : alert.lastAbove;
    await _db.writeTxn(() => _db.priceAlerts.put(alert));
    await _reload();
    await _pushToNative();
  }

  Future<void> remove(PriceAlert alert) async {
    await _db.writeTxn(() => _db.priceAlerts.delete(alert.id));
    await _reload();
    await _pushToNative();
  }

  /// Compares every alert against the newest quotes and fires the crossings.
  Future<void> _check(Map<String, Quote> quotes) {
    // Until the background job's state has been folded in, evaluating could
    // re-announce a crossing that already happened while the app was closed.
    if (!_synced) return Future<void>.value();
    final pending = _checking;
    if (pending != null) return pending;
    final future = _runCheck(quotes).whenComplete(() => _checking = null);
    _checking = future;
    return future;
  }

  Future<void> _runCheck(Map<String, Quote> quotes) async {
    final before = {
      for (final alert in state.alerts) alert.id: alert.lastAbove,
    };
    final pass = evaluateAlertRules(alerts: state.alerts, quotes: quotes);
    final changed = [
      for (final alert in pass.alerts)
        if (before[alert.id] != alert.lastAbove) alert,
    ];
    if (changed.isEmpty) return;

    // Persist before notifying: a crash between the two would otherwise let
    // the same crossing fire again on the next launch.
    await _db.writeTxn(() => _db.priceAlerts.putAll(changed));
    await _reload();
    await _pushToNative();

    final notifier = _ref.read(alertNotifierProvider);
    for (final fired in pass.fired) {
      final message = alertNotification(fired.alert, fired.price);
      await notifier.notify(
        id: fired.alert.id,
        title: message.title,
        body: message.body,
      );
    }
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>(
  (ref) => AlertsNotifier(ref),
);
