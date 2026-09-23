import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/providers.dart';
import '../services/widget_sync.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';

/// Home watchlist: a grid of live quotes with pull-to-refresh. Fetching and the
/// refresh schedule live in [QuoteBoard], which serves every screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // The Android home-screen widget mirrors the watchlist, so the snapshot is
    // rewritten whenever the symbols or their prices change.
    ref.listenManual(watchlistQuotesProvider, (_, _) => _saveSnapshot());
    ref.listenManual(watchlistProvider, (_, _) => _saveSnapshot());
  }

  Future<void> _saveSnapshot() async {
    if (!mounted) return;
    final quotes = ref.read(watchlistQuotesProvider);
    if (quotes.isEmpty) return;
    await WidgetSync.saveSnapshot(
      symbols: ref.read(watchlistProvider).symbols,
      quotes: quotes,
      dark: Theme.of(context).brightness == Brightness.dark,
      roundTwoDp: ref.read(appPrefsProvider).roundTwoDp,
      updatedAt: ref.read(quoteBoardProvider).lastFetch,
    );
  }

  Future<void> _refresh({bool manual = false}) async {
    await ref.read(quoteBoardProvider.notifier).refresh();
    if (!mounted || !manual) return;
    final error = ref.read(quoteBoardProvider).error;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
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
        ],
      ),
    );
  }

  Widget _buildStatusLine(BuildContext context, AppPrefs prefs) {
    final theme = Theme.of(context);
    final board = ref.watch(quoteBoardProvider);
    final last = board.lastFetch;
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
          if (board.fetching && board.quotes.isEmpty)
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
              onPressed: () => _refresh(manual: true),
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    final board = ref.watch(quoteBoardProvider);
    if (!watchlist.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (watchlist.symbols.isEmpty) {
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
    var quotes = ref.watch(watchlistQuotesProvider);
    if (ref.watch(appPrefsProvider).autoSort) {
      quotes = List.of(quotes)
        ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    }
    if (quotes.isEmpty && board.fetching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (quotes.isEmpty && board.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: muted),
              const SizedBox(height: 10),
              Text(
                board.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _refresh(manual: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
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
                      final quote = quotes[index];
                      return QuoteCard(
                        quote: quote,
                        roundTwoDp: ref.read(appPrefsProvider).roundTwoDp,
                        onTap: () => _openDetail(quote),
                        onRemove: () => _confirmRemove(quote),
                      );
                    },
                    childCount: quotes.length,
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
