import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/providers.dart';
import '../services/yahoo_service.dart';
import '../services/widget_sync.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Home watchlist: a grid of live quotes with pull-to-refresh and automatic
/// refresh every [AppPrefs.refreshMinutes] minutes.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Quote> _quotes = const [];
  List<String> _symbols = const [];
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  DateTime? _lastFetch;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ref.listenManual(watchlistProvider, (_, symbols) {
      _onSymbolsChanged(symbols);
    });
    ref.listenManual(appPrefsProvider, (previous, next) {
      _rescheduleTimer();
      if (previous != null && next.refreshMinutes != previous.refreshMinutes) {
        _fetch();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onSymbolsChanged(List<String> symbols) async {
    _symbols = List.of(symbols);
    await _fetch();
  }

  void _rescheduleTimer() {
    _timer?.cancel();
    final minutes = ref.read(appPrefsProvider).refreshMinutes;
    if (minutes <= 0) return;
    _timer = Timer.periodic(
      Duration(minutes: minutes),
      (_) => _fetch(),
    );
  }

  Future<void> _fetch({bool manual = false}) async {
    if (_fetching) return;
    if (_symbols.isEmpty) {
      setState(() {
        _loading = false;
        _quotes = const [];
        _error = null;
      });
      return;
    }
    _fetching = true;
    if (manual || _quotes.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = ref.read(yahooApiProvider);
      var quotes = await api.fetchQuotes(_symbols);
      final prefs = ref.read(appPrefsProvider);
      if (prefs.autoSort) {
        quotes = List.of(quotes)
          ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
      }
      if (!mounted) return;
      setState(() {
        _quotes = quotes;
        _error = null;
        _lastFetch = DateTime.now();
        _loading = false;
      });
      await WidgetSync.saveSnapshot(
        symbols: _symbols,
        quotes: quotes,
        dark: Theme.of(context).brightness == Brightness.dark,
        roundTwoDp: ref.read(appPrefsProvider).roundTwoDp,
        updatedAt: _lastFetch,
      );
    } catch (error, stackTrace) {
      debugPrint('fetch quotes failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error);
        _loading = false;
      });
      if (manual) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } finally {
      _fetching = false;
    }
  }

  String _messageFor(Object error) {
    if (error is YahooFinanceException) return error.message;
    return 'Unable to fetch quotes. Check your connection and try again.';
  }

  Future<void> _confirmRemove(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove symbol'),
        content: Text('Remove ${quote.symbol} from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(watchlistProvider.notifier).remove(quote.symbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPrefsProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            _buildStatusLine(context, prefs),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kAppName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Watchlist',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Add symbols',
            onPressed: () => _openSearch(),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(BuildContext context, AppPrefs prefs) {
    final theme = Theme.of(context);
    final last = _lastFetch;
    final next = (last == null)
        ? null
        : last.add(Duration(minutes: prefs.refreshMinutes));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Row(
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Last fetch: ${last == null ? '--' : hhMm(last)}'
              '  ·  Next fetch: ${next == null ? '--' : hhMm(next)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_loading && _quotes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Refresh now',
              visualDensity: VisualDensity.compact,
              onPressed: () => _fetch(manual: true),
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading && _symbols.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_symbols.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_chart_rounded, size: 56, color: muted),
            const SizedBox(height: 12),
            const Text('Your watchlist is empty'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Add stocks'),
            ),
          ],
        ),
      );
    }
    if (_quotes.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quotes.isEmpty && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: muted),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _fetch(manual: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(manual: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900
              ? 4
              : width >= 560
                  ? 3
                  : 2;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.45,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final quote = _quotes[index];
                      return QuoteCard(
                        quote: quote,
                        roundTwoDp: ref.read(appPrefsProvider).roundTwoDp,
                        onTap: () => _openDetail(quote),
                        onRemove: () => _confirmRemove(quote),
                      );
                    },
                    childCount: _quotes.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
    );
  }

  void _openDetail(Quote quote) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteDetailScreen(initialQuote: quote),
      ),
    );
  }
}
