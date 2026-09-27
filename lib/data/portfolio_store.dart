import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/alert.dart';
import '../domain/portfolio_math.dart';
import '../domain/position.dart';
import '../domain/transaction.dart';
import 'market_data.dart';

/// Persistence boundary for the portfolio product.
///
/// Deliberately small and dumb: transactions and alerts are stored, everything
/// else (quantities, average cost, P&L, allocation) is derived on read by
/// `domain/portfolio_math.dart`. Keeping derived values out of storage is what
/// makes edits and deletes safe — there is nothing to keep in sync.
///
/// The interface exists so the storage engine can change without touching the
/// UI: the shipping implementation will be SQLite, but the in-memory one below
/// keeps tests and previews free of platform dependencies.
abstract class PortfolioStore {
  Future<List<Transaction>> loadTransactions();

  Future<void> saveTransaction(Transaction transaction);

  Future<void> deleteTransaction(String id);

  Future<List<Alert>> loadAlerts();

  Future<void> saveAlert(Alert alert);

  Future<void> deleteAlert(String id);
}

/// List-backed store used by tests, previews and the pre-storage build.
class InMemoryPortfolioStore implements PortfolioStore {
  InMemoryPortfolioStore({
    Iterable<Transaction> transactions = const [],
    Iterable<Alert> alerts = const [],
  })  : _transactions = [...transactions],
        _alerts = [...alerts];

  final List<Transaction> _transactions;
  final List<Alert> _alerts;

  @override
  Future<List<Transaction>> loadTransactions() async =>
      List.unmodifiable(_transactions);

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final index =
        _transactions.indexWhere((existing) => existing.id == transaction.id);
    if (index == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[index] = transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
  }

  @override
  Future<List<Alert>> loadAlerts() async => List.unmodifiable(_alerts);

  @override
  Future<void> saveAlert(Alert alert) async {
    final index = _alerts.indexWhere((existing) => existing.id == alert.id);
    if (index == -1) {
      _alerts.add(alert);
    } else {
      _alerts[index] = alert;
    }
  }

  @override
  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((alert) => alert.id == id);
  }
}

/// Must be overridden in `main()` (or a test) with the real store.
final portfolioStoreProvider = Provider<PortfolioStore>(
  (ref) => throw UnimplementedError(
    'portfolioStoreProvider must be overridden in main()',
  ),
);

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._store) : super(const []) {
    _load();
  }

  final PortfolioStore _store;

  Future<void> _load() async {
    final transactions = await _store.loadTransactions();
    if (!mounted) return;
    state = transactions;
  }

  Future<void> add(Transaction transaction) async {
    await _store.saveTransaction(transaction);
    if (!mounted) return;
    state = [...state, transaction];
  }

  Future<void> remove(String id) async {
    await _store.deleteTransaction(id);
    if (!mounted) return;
    state = state.where((transaction) => transaction.id != id).toList();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => TransactionsNotifier(ref.watch(portfolioStoreProvider)),
);

class AlertsNotifier extends StateNotifier<List<Alert>> {
  AlertsNotifier(this._store) : super(const []) {
    _load();
  }

  final PortfolioStore _store;

  Future<void> _load() async {
    final alerts = await _store.loadAlerts();
    if (!mounted) return;
    state = alerts;
  }

  Future<void> _replace(Alert alert) async {
    await _store.saveAlert(alert);
    if (!mounted) return;
    state = [
      for (final existing in state)
        if (existing.id == alert.id) alert else existing,
      if (!state.any((existing) => existing.id == alert.id)) alert,
    ];
  }

  Future<void> add(Alert alert) => _replace(alert);

  Future<void> toggleEnabled(Alert alert) =>
      _replace(alert.copyWith(enabled: !alert.enabled));

  /// Clears the fired marker so the rule can notify again.
  Future<void> reArm(Alert alert) =>
      _replace(alert.copyWith(clearTriggeredAt: true));

  Future<void> markTriggered(Alert alert, DateTime at) =>
      _replace(alert.copyWith(triggeredAt: at));

  Future<void> remove(String id) async {
    await _store.deleteAlert(id);
    if (!mounted) return;
    state = state.where((alert) => alert.id != id).toList();
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, List<Alert>>(
  (ref) => AlertsNotifier(ref.watch(portfolioStoreProvider)),
);

/// Positions, realized P&L and data warnings, recomputed from transactions.
final ledgerProvider = Provider<LedgerResult>(
  (ref) => buildLedger(ref.watch(transactionsProvider)),
);

/// Symbols worth fetching a price for: open positions plus anything an armed
/// alert is watching. Avoids polling the demo watchlist when the user only
/// holds two names.
final trackedSymbolsProvider = Provider<List<String>>((ref) {
  final ledger = ref.watch(ledgerProvider);
  final alerts = ref.watch(alertsProvider);
  final symbols = <String>{
    for (final transaction in ref.watch(transactionsProvider))
      transaction.symbol,
    for (final alert in alerts) alert.symbol,
  };
  // Open positions first so the table has prices even if the set grows.
  final ordered = ledger.openPositions.map((position) => position.symbol).toList();
  for (final symbol in symbols) {
    if (!ordered.contains(symbol)) ordered.add(symbol);
  }
  return ordered;
});

/// Latest price per symbol, converted into the portfolio's base currency (MXN).
///
/// Foreign holdings without a usable FX rate are dropped from the map instead
/// of being valued at a made-up 1:1 rate; the valuation then flags them as
/// missing, which is honest, whereas a wrong total is not.
final portfolioPricesProvider =
    FutureProvider<Map<String, PriceSnapshot>>((ref) async {
  final symbols = ref.watch(trackedSymbolsProvider);
  if (symbols.isEmpty) return const {};

  final market = ref.watch(marketDataProvider);
  final quotes = await market.quotes(symbols);
  if (quotes.isEmpty) return const {};

  final foreignCurrencies = quotes
      .map((quote) => quote.currency)
      .where((currency) => currency.isNotEmpty && currency != _baseCurrency)
      .toSet();

  final rates = <String, double>{_baseCurrency: 1};
  for (final currency in foreignCurrencies) {
    final rate = await market.fxRate(currency, _baseCurrency);
    if (rate != null) rates[currency] = rate;
  }

  final snapshots = <String, PriceSnapshot>{};
  for (final quote in quotes) {
    final currency = quote.currency.isEmpty ? _baseCurrency : quote.currency;
    final rate = rates[currency];
    if (rate == null) continue;
    snapshots[quote.symbol] = PriceSnapshot(
      symbol: quote.symbol,
      price: quote.lastPrice,
      previousClose: quote.previousClose,
      currency: currency,
      fxRate: rate,
      asOf: DateTime.now(),
    );
  }
  return snapshots;
});

const String _baseCurrency = 'MXN';

/// Portfolio totals for the dashboard.
final portfolioValuationProvider = Provider<PortfolioValuation>((ref) {
  final prices = ref.watch(portfolioPricesProvider).valueOrNull ?? const {};
  return valuePortfolio(ledger: ref.watch(ledgerProvider), prices: prices);
});

/// Demo holdings, so the product is explorable on a fresh device.
///
/// Controlled by `--dart-define=DEMO_PORTFOLIO=false`; it must be off for any
/// build shown to a real user.
const bool kSeedDemoPortfolio =
    bool.fromEnvironment('DEMO_PORTFOLIO', defaultValue: true);

/// Writes the demo portfolio only into an empty store, so a device with real
/// data — or a user who deleted everything on purpose — is never re-seeded.
Future<void> seedDemoPortfolioIfEmpty(PortfolioStore store) async {
  if ((await store.loadTransactions()).isNotEmpty) return;
  if ((await store.loadAlerts()).isNotEmpty) return;
  for (final transaction in demoTransactions()) {
    await store.saveTransaction(transaction);
  }
  for (final alert in demoAlerts()) {
    await store.saveAlert(alert);
  }
}

List<Transaction> demoTransactions() => <Transaction>[
    Transaction(
      id: 'demo-1',
      symbol: 'WALMEX.MX',
      side: TradeSide.buy,
      quantity: 120,
      price: 58.40,
      fees: 84,
      executedAt: DateTime(2026, 2, 12),
      note: 'Entrada inicial',
    ),
    Transaction(
      id: 'demo-2',
      symbol: 'WALMEX.MX',
      side: TradeSide.buy,
      quantity: 80,
      price: 62.15,
      fees: 62,
      executedAt: DateTime(2026, 4, 3),
    ),
    Transaction(
      id: 'demo-3',
      symbol: 'FEMSAUBD.MX',
      side: TradeSide.buy,
      quantity: 40,
      price: 196.30,
      fees: 96,
      executedAt: DateTime(2026, 3, 20),
    ),
    Transaction(
      id: 'demo-4',
      symbol: 'FEMSAUBD.MX',
      side: TradeSide.sell,
      quantity: 10,
      price: 214.80,
      fees: 32,
      executedAt: DateTime(2026, 6, 8),
      note: 'Toma de utilidades',
    ),
    Transaction(
      id: 'demo-5',
      symbol: 'CEMEXCPO.MX',
      side: TradeSide.buy,
      quantity: 900,
      price: 12.85,
      fees: 70,
      executedAt: DateTime(2026, 5, 15),
    ),
  ];

List<Alert> demoAlerts() => <Alert>[
    Alert(
      id: 'alert-1',
      symbol: 'WALMEX.MX',
      kind: AlertKind.priceAbove,
      threshold: 70,
      createdAt: DateTime(2026, 6, 1),
    ),
    Alert(
      id: 'alert-2',
      symbol: 'CEMEXCPO.MX',
      kind: AlertKind.percentChangeBelow,
      threshold: -3,
      createdAt: DateTime(2026, 6, 2),
    ),
  ];
