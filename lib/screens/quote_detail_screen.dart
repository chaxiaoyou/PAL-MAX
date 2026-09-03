import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/quote.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/price_chart.dart';
import 'webview_screen.dart';

enum _ChartRange {
  oneDay('1D', '1d', '1h'),
  twoWeeks('2W', '14d', '1d'),
  oneMonth('1M', '1mo', '1d'),
  threeMonths('3M', '3mo', '1d'),
  oneYear('1Y', '1y', '1d'),
  fiveYears('5Y', '5y', '1d'),
  max('Max', 'max', '1d');

  const _ChartRange(this.label, this.range, this.interval);

  final String label;
  final String range;
  final String interval;
}

class QuoteDetailScreen extends ConsumerStatefulWidget {
  const QuoteDetailScreen({super.key, required this.initialQuote});

  final Quote initialQuote;

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  late Quote _quote = widget.initialQuote;
  _ChartRange _range = _ChartRange.oneDay;
  List<ChartPoint> _chartPoints = const [];
  List<NewsItem> _news = const [];
  bool _chartLoading = true;
  bool _newsLoading = true;
  String? _chartError;
  bool _refreshingQuote = false;

  @override
  void initState() {
    super.initState();
    _loadChart();
    _loadNews();
  }

  Future<void> _loadChart() async {
    if (!_chartLoading) {
      setState(() {
        _chartLoading = true;
        _chartError = null;
      });
    }
    try {
      final points = await ref
          .read(yahooApiProvider)
          .fetchChart(_quote.symbol, range: _range.range, interval: _range.interval);
      if (!mounted) return;
      setState(() {
        _chartPoints = points;
        _chartLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('chart fetch failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _chartError = 'Unable to load chart data.';
        _chartLoading = false;
      });
    }
  }

  Future<void> _loadNews() async {
    try {
      final news = await ref.read(yahooApiProvider).fetchNews(_quote.symbol);
      if (!mounted) return;
      setState(() {
        _news = news;
        _newsLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('news fetch failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _newsLoading = false);
    }
  }

  Future<void> _refreshQuote() async {
    setState(() => _refreshingQuote = true);
    try {
      final quotes = await ref.read(yahooApiProvider).fetchQuote(_quote.symbol);
      if (!mounted) return;
      if (quotes.isNotEmpty) {
        setState(() => _quote = quotes.first);
      }
    } catch (error, stackTrace) {
      debugPrint('quote refresh failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Unable to refresh quote')));
      }
    } finally {
      if (mounted) setState(() => _refreshingQuote = false);
    }
  }

  Future<void> _toggleWatchlist() async {
    final notifier = ref.read(watchlistProvider.notifier);
    final contains = ref.read(watchlistProvider).contains(_quote.symbol);
    if (contains) {
      await notifier.remove(_quote.symbol);
    } else {
      await notifier.add(_quote.symbol);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              contains
                  ? '${_quote.symbol} removed from watchlist'
                  : '${_quote.symbol} added to watchlist',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inWatchlist = ref.watch(
      watchlistProvider.select((symbols) => symbols.contains(_quote.symbol)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_quote.symbol),
        actions: [
          IconButton(
            tooltip: inWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
            onPressed: _toggleWatchlist,
            icon: Icon(
              inWatchlist ? Icons.star_rounded : Icons.add_rounded,
              color: inWatchlist ? Colors.amber.shade600 : null,
            ),
          ),
          IconButton(
            tooltip: 'Refresh quote',
            onPressed: _refreshingQuote ? null : _refreshQuote,
            icon: _refreshingQuote
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshQuote,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildChartCard(context)),
            SliverToBoxAdapter(child: _buildStatsCard(context)),
            SliverToBoxAdapter(child: _buildNewsCard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final color = changeColor(
      context,
      _quote.isUp
          ? QuoteDirection.up
          : _quote.isDown
              ? QuoteDirection.down
              : QuoteDirection.flat,
    );
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    final symbol = currencySymbol(_quote.currency);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _quote.name.isEmpty ? _quote.symbol : _quote.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$symbol${priceText(_quote.lastPrice, roundTwoDp: round2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${percentText(_quote.changePercent)}  '
                '${signedAmount(_quote.change, roundTwoDp: round2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _marketStateLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _marketStateLabel() {
    final state = _quote.marketState.toUpperCase();
    if (state == 'REGULAR') return 'Market open';
    if (state == 'PRE') return 'Pre-market';
    if (state == 'POST') return 'After hours';
    return 'Market closed';
  }

  Widget _buildChartCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _ChartRange.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final range = _ChartRange.values[index];
                    final selected = range == _range;
                    return ChoiceChip(
                      label: Text(range.label),
                      selected: selected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        if (range == _range) return;
                        _range = range;
                        _loadChart();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (_chartLoading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_chartError != null)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_chartError!, style: const TextStyle(color: muted)),
                        TextButton(
                          onPressed: _loadChart,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                PriceChart(
                  points: _chartPoints,
                  color: _chartColor(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _chartColor(BuildContext context) {
    if (_chartPoints.length >= 2) {
      final first = _chartPoints.first.close;
      final last = _chartPoints.last.close;
      if (last > first) return positiveColor(context);
      if (last < first) return negativeColor(context);
    }
    if (_quote.isUp) return positiveColor(context);
    if (_quote.isDown) return negativeColor(context);
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildStatsCard(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _buildStats();
    if (stats.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key statistics',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.6,
                mainAxisSpacing: 4,
                children: [
                  for (final stat in stats)
                    _StatCell(label: stat.label, value: stat.value),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String label, String value})> _buildStats() {
    final q = _quote;
    final round2 = ref.read(appPrefsProvider).roundTwoDp;
    String money(double? v, {bool two = true}) =>
        v == null ? '—' : priceText(v, roundTwoDp: round2 && two);
    String compact(num? v) => v == null ? '—' : compactNumber(v);

    final stats = <({String label, String value})>[];
    void add(String label, String value) =>
        stats.add((label: label, value: value));
    add('Open', money(q.open));
    add('Previous close', money(q.previousClose));
    if (q.dayLow != null && q.dayHigh != null) {
      add('Day range', '${money(q.dayLow)} – ${money(q.dayHigh)}');
    }
    add('Volume', compact(q.volume));
    add('Market cap', compact(q.marketCap));
    add('P/E ratio', q.trailingPE == null ? '—' : money(q.trailingPE, two: false));
    if (q.fiftyTwoWeekLow != null && q.fiftyTwoWeekHigh != null) {
      add(
        '52-week range',
        '${money(q.fiftyTwoWeekLow)} – ${money(q.fiftyTwoWeekHigh)}',
      );
    }
    add('50-day avg.', money(q.fiftyDayAverage));
    add('200-day avg.', money(q.twoHundredDayAverage));
    return stats;
  }

  Widget _buildNewsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Related news',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (_newsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_news.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text('No news available', style: TextStyle(color: muted)),
                  ),
                )
              else
                for (final item in _news.take(6)) _NewsTile(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WebViewScreen(url: item.link),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _dateLabel(item.pubDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year && local.month == now.month && local.day == now.day;
    final formatter = DateFormat(sameDay ? 'HH:mm' : 'MMM d, yyyy');
    return formatter.format(local);
  }
}
