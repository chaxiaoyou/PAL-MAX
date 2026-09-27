import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../models/quote.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/price_chart.dart';

enum _ChartRange {
  oneDay('1D', '1d', '1h'),
  twoWeeks('2W', '14d', '1d'),
  oneMonth('1M', '1mo', '1d'),
  threeMonths('3M', '3mo', '1d'),
  oneYear('1Y', '1y', '1d'),
  fiveYears('5Y', '5y', '1d'),
  max('', 'max', '1d');

  const _ChartRange(this.fixedLabel, this.range, this.interval);

  final String fixedLabel;
  final String range;
  final String interval;

  /// Range chips stay numeric (a chart axis convention) except for "Max".
  String label(AppLocalizations l10n) =>
      this == _ChartRange.max ? l10n.chartRangeMax : fixedLabel;
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
        _chartError = context.l10n.detailChartFailed;
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
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.detailRefreshFailed)),
          );
      }
    } finally {
      if (mounted) setState(() => _refreshingQuote = false);
    }
  }

  Future<void> _toggleWatchlist() async {
    final l10n = context.l10n;
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
                  ? l10n.detailRemovedFromWatchlist(_quote.symbol)
                  : l10n.detailAddedToWatchlist(_quote.symbol),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inWatchlist = ref.watch(
      watchlistProvider.select((symbols) => symbols.contains(_quote.symbol)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_quote.symbol),
        actions: [
          IconButton(
            tooltip: inWatchlist
                ? l10n.detailRemoveFromWatchlist
                : l10n.detailAddToWatchlist,
            onPressed: _toggleWatchlist,
            icon: Icon(
              inWatchlist ? Icons.star_rounded : Icons.add_rounded,
              color: inWatchlist ? Colors.amber.shade600 : null,
            ),
          ),
          IconButton(
            tooltip: l10n.detailRefreshQuote,
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
      padding: const EdgeInsets.fromLTRB(20, kSpace1, 20, kSpace3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _quote.name.isEmpty ? _quote.symbol : _quote.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: kSpace1),
          Text(
            '$symbol${priceText(_quote.lastPrice, roundTwoDp: round2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              fontFeatures: kTabular,
            ),
          ),
          const SizedBox(height: kSpace2),
          // Wrap instead of Row: a long change string plus the market-state
          // label used to overflow the header line on narrow screens.
          Wrap(
            spacing: kSpace3,
            runSpacing: kSpace1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${percentText(_quote.changePercent)}  '
                '${signedAmount(_quote.change, roundTwoDp: round2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: kTabular,
                ),
              ),
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
    final l10n = context.l10n;
    final state = _quote.marketState.toUpperCase();
    if (state == 'REGULAR') return l10n.marketOpen;
    if (state == 'PRE') return l10n.marketPreMarket;
    if (state == 'POST') return l10n.marketAfterHours;
    return l10n.marketClosed;
  }

  Widget _buildChartCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, kSpace3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kSpace3, kSpace3, kSpace3, kSpace2),
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
                      label: Text(range.label(context.l10n)),
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
                        Text(
                          _chartError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadChart,
                          child: Text(context.l10n.actionRetry),
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
      padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, kSpace3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(kSpace4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.detailKeyStatistics,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                mainAxisSpacing: kSpace1,
                crossAxisSpacing: kSpace3,
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
    final l10n = context.l10n;
    final round2 = ref.read(appPrefsProvider).roundTwoDp;
    String money(double? v, {bool two = true}) =>
        v == null ? '—' : priceText(v, roundTwoDp: round2 && two);
    String compact(num? v) => v == null ? '—' : compactNumber(v);

    final stats = <({String label, String value})>[];
    void add(String label, String value) =>
        stats.add((label: label, value: value));
    add(l10n.statOpen, money(q.open));
    add(l10n.statPreviousClose, money(q.previousClose));
    if (q.dayLow != null && q.dayHigh != null) {
      add(l10n.statDayRange, '${money(q.dayLow)} – ${money(q.dayHigh)}');
    }
    add(l10n.statVolume, compact(q.volume));
    add(l10n.statMarketCap, compact(q.marketCap));
    add(
      l10n.statPeRatio,
      q.trailingPE == null ? '—' : money(q.trailingPE, two: false),
    );
    if (q.fiftyTwoWeekLow != null && q.fiftyTwoWeekHigh != null) {
      add(
        l10n.stat52WeekRange,
        '${money(q.fiftyTwoWeekLow)} – ${money(q.fiftyTwoWeekHigh)}',
      );
    }
    add(l10n.stat50DayAvg, money(q.fiftyDayAverage));
    add(l10n.stat200DayAvg, money(q.twoHundredDayAverage));
    return stats;
  }

  Widget _buildNewsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, kSpace3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kSpace4, kSpace4, kSpace4, kSpace2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.detailRelatedNews,
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      context.l10n.detailNoNews,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
            fontFeatures: kTabular,
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
      onTap: () => _openArticle(context),
      borderRadius: BorderRadius.circular(kRadiusControl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpace2, horizontal: kSpace1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: kSpace1),
                  Text(
                    _dateLabel(context, item.pubDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: kTabular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpace2),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the article in the device browser.
  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.tryParse(item.link.trim());
    if (uri == null || !uri.hasScheme) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (error) {
      debugPrint('Failed to open news link: $error');
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.detailOpenArticleFailed)),
    );
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year && local.month == now.month && local.day == now.day;
    final formatter = sameDay
        ? DateFormat.Hm()
        : DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return formatter.format(local);
  }
}
