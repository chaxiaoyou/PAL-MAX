import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/providers.dart';
import '../services/yahoo_service.dart';
import '../services/widget_sync.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// How the list below the index strip is filtered.
enum _ListFilter {
  all('All'),
  gainers('Gainers'),
  losers('Losers');

  const _ListFilter(this.label);

  final String label;
}

/// Watchlist home.
///
/// Composition, top to bottom: a compact header, a horizontally scrolling
/// strip with the market indices, a one-tap filter row and finally the
/// watchlist itself as a ranked list (price, change and a direction bar).
/// Rows can be swiped away to unsubscribe from a symbol.
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
  _ListFilter _filter = _ListFilter.all;

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
    if (!mounted) return;
    // Rebuild right away: a swipe-removed row must leave the tree immediately,
    // otherwise Dismissible complains that a dismissed child is still present.
    setState(() => _symbols = List.of(symbols));
    await _fetch();
  }

  void _rescheduleTimer() {
    _timer?.cancel();
    final minutes = ref.read(appPrefsProvider).refreshMinutes;
    if (minutes <= 0) return;
    _timer = Timer.periodic(Duration(minutes: minutes), (_) => _fetch());
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

  /// Quotes still present in the watchlist, so a swipe-removed row disappears
  /// immediately instead of waiting for the next fetch.
  List<Quote> get _liveQuotes {
    final symbols = _symbols.toSet();
    return _quotes.where((quote) => symbols.contains(quote.symbol)).toList();
  }

  Future<bool> _askRemove(Quote quote) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _remove(Quote quote) =>
      ref.read(watchlistProvider.notifier).remove(quote.symbol);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, kSpace3, kSpace2, kSpace1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kAppName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Markets',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Add symbols',
            onPressed: _openSearch,
            icon: const Icon(Icons.add_circle_outline_rounded),
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

  Widget _buildBody(BuildContext context) {
    if (_loading && _symbols.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_symbols.isEmpty) {
      return _buildEmptyState(context);
    }
    if (_liveQuotes.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_liveQuotes.isEmpty && _error != null) {
      return _buildErrorState(context);
    }

    final quotes = _liveQuotes;
    final indices = quotes.where((quote) => quote.isIndex).toList();
    final hero = (indices.isNotEmpty ? indices : quotes).take(4).toList();
    final heroSymbols = hero.map((quote) => quote.symbol).toSet();
    final rest = quotes
        .where((quote) => !heroSymbols.contains(quote.symbol))
        .where(_matchesFilter)
        .toList();

    return RefreshIndicator(
      onRefresh: () => _fetch(manual: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (hero.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, kSpace3, 20, kSpace2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        indices.isNotEmpty ? 'Market indices' : 'Pinned',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    _staleBadge(context),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildHeroStrip(context, hero)),
          ],
          SliverToBoxAdapter(child: _buildListHeader(context, rest.length)),
          if (rest.isEmpty)
            SliverToBoxAdapter(child: _buildNoRows(context, hero.isEmpty))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList.separated(
                itemCount: rest.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final quote = rest[index];
                  return _WatchRow(
                    quote: quote,
                    roundTwoDp: ref.watch(appPrefsProvider).roundTwoDp,
                    onTap: () => _openDetail(quote),
                    onRemove: () => _remove(quote),
                    confirmRemove: () => _askRemove(quote),
                  );
                },
              ),
            ),
          SliverToBoxAdapter(child: _buildFooter(context)),
        ],
      ),
    );
  }

  bool _matchesFilter(Quote quote) => switch (_filter) {
        _ListFilter.all => true,
        _ListFilter.gainers => quote.changePercent > 0,
        _ListFilter.losers => quote.changePercent < 0,
      };

  Widget _buildHeroStrip(BuildContext context, List<Quote> hero) {
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, kSpace1),
        itemCount: hero.length,
        separatorBuilder: (_, _) => const SizedBox(width: kSpace2),
        itemBuilder: (context, index) => _HeroQuoteCard(
          quote: hero[index],
          roundTwoDp: round2,
          onTap: () => _openDetail(hero[index]),
        ),
      ),
    );
  }

  /// Title row plus a scrollable filter rail.
  ///
  /// The chips used to share one line with the title, which overflowed as soon
  /// as the labels grew (large text scales, longer locales). Giving them their
  /// own row keeps the heading stable and the controls reachable.
  Widget _buildListHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, kSpace4, 20, kSpace2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Watchlist',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: kSpace2),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: kTabular,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final filter in _ListFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _filter == filter
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _staleBadge(BuildContext context) {
    final theme = Theme.of(context);
    final last = _lastFetch;
    return Row(
      children: [
        Text(
          last == null ? 'Updating…' : 'Updated ${hhMm(last)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 2),
        if (_loading && _quotes.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            tooltip: 'Refresh now',
            visualDensity: VisualDensity.compact,
            onPressed: () => _fetch(manual: true),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
      ],
    );
  }

  Widget _buildNoRows(BuildContext context, bool emptyHero) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.playlist_add_rounded,
              size: 34,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 10),
            Text(
              emptyHero
                  ? 'Your watchlist is empty'
                  : _filter == _ListFilter.all
                      ? 'Only indices so far — add a few stocks'
                      : 'No ${_filter.label.toLowerCase()} in the watchlist',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Add symbols'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.candlestick_chart_outlined,
              size: 54,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              'Build your watchlist',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search a ticker or company name to start tracking live quotes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Add symbols'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(appPrefsProvider);
    final last = _lastFetch;
    final next = last?.add(Duration(minutes: prefs.refreshMinutes));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
      child: Center(
        child: Text(
          'Auto-refresh every ${prefs.refreshMinutes} min'
          '  ·  ${next == null ? 'no fetch yet' : 'next ${hhMm(next)}'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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

/// Large index card used by the horizontal strip above the watchlist.
class _HeroQuoteCard extends StatelessWidget {
  const _HeroQuoteCard({
    required this.quote,
    required this.roundTwoDp,
    required this.onTap,
  });

  final Quote quote;
  final bool roundTwoDp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = quote.isUp
        ? QuoteDirection.up
        : quote.isDown
            ? QuoteDirection.down
            : QuoteDirection.flat;
    final color = changeColor(context, direction);
    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Ink(
            decoration: BoxDecoration(
              // Flat surface plus a direction rule, echoing the bar used by the
              // watchlist rows below. The gradient this replaced only muddied
              // the card against the tinted canvas.
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 3, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(kSpace3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote.symbol,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            quote.name.isEmpty ? '—' : quote.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${currencySymbol(quote.currency)}'
                              '${priceText(quote.lastPrice, roundTwoDp: roundTwoDp)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: kTabular,
                              ),
                            ),
                          ),
                          const SizedBox(height: kSpace1),
                          Text(
                            '${percentText(quote.changePercent)}  '
                            '${signedAmount(quote.change, roundTwoDp: roundTwoDp)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontFeatures: kTabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row in the watchlist: direction bar, symbol/name, price and change.
class _WatchRow extends StatelessWidget {
  const _WatchRow({
    required this.quote,
    required this.roundTwoDp,
    required this.onTap,
    required this.onRemove,
    required this.confirmRemove,
  });

  final Quote quote;
  final bool roundTwoDp;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final Future<bool> Function() confirmRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = quote.isUp
        ? QuoteDirection.up
        : quote.isDown
            ? QuoteDirection.down
            : QuoteDirection.flat;
    final color = changeColor(context, direction);

    return Dismissible(
      key: ValueKey('watch-${quote.symbol}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmRemove(),
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(kRadiusCard),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onError,
        ),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusCard),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kSpace3, 10, kSpace1, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: kSpace3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        quote.name.isEmpty ? '—' : quote.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currencySymbol(quote.currency)}'
                      '${priceText(quote.lastPrice, roundTwoDp: roundTwoDp)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: kTabular,
                      ),
                    ),
                    const SizedBox(height: kSpace1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentText(quote.changePercent)}  '
                        '${signedAmount(quote.change, roundTwoDp: roundTwoDp)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontFeatures: kTabular,
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
