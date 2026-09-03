import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

const _trendingSymbols = <String>[
  '^GSPC',
  '^DJI',
  '^IXIC',
  'AAPL',
  'MSFT',
  'NVDA',
  'GOOG',
  'AMZN',
  'META',
  'TSLA',
  'AMD',
  'PLTR',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResult> _results = const [];
  List<Quote> _trending = const [];
  bool _searching = false;
  bool _trendingLoading = true;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _trendingLoading = true);
    try {
      final quotes = await ref
          .read(yahooApiProvider)
          .fetchQuotes(_trendingSymbols);
      if (!mounted) return;
      setState(() {
        _trending = quotes;
        _trendingLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('trending fetch failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _trendingLoading = false);
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {}); // Reflect the clear (suffix) icon immediately.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await ref.read(yahooApiProvider).search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (error, stackTrace) {
      debugPrint('search failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _searchError = 'Search failed. Please try again.';
        _searching = false;
      });
    }
  }

  Future<void> _add(String symbol) async {
    final alreadyAdded = ref.read(watchlistProvider).contains(symbol);
    if (alreadyAdded) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$symbol is already in your watchlist')));
      return;
    }
    await ref.read(watchlistProvider.notifier).add(symbol);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$symbol added to watchlist')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add symbols')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                final trimmed = value.trim();
                if (trimmed.isNotEmpty) _search(trimmed);
              },
              decoration: InputDecoration(
                hintText: 'Search symbol or company (e.g. AAPL)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _controller.text.trim().isEmpty
                ? _buildTrending()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    if (_trendingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'Trending',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final quote in _trending) _TrendingTile(quote: quote, onAdd: _add),
        if (_trending.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('Unable to load trending symbols')),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null && _results.isEmpty) {
      return Center(child: Text(_searchError!, style: const TextStyle(color: muted)));
    }
    if (_results.isEmpty && !_searching) {
      return const Center(child: Text('No symbols found'));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final result = _results[index];
        return _SearchResultTile(result: result, onAdd: _add);
      },
    );
  }
}

class _TrendingTile extends ConsumerWidget {
  const _TrendingTile({required this.quote, required this.onAdd});

  final Quote quote;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final added = ref.watch(
      watchlistProvider.select((symbols) => symbols.contains(quote.symbol)),
    );
    final color = changeColor(
      context,
      quote.isUp
          ? QuoteDirection.up
          : quote.isDown
              ? QuoteDirection.down
              : QuoteDirection.flat,
    );
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    return ListTile(
      title: Text(
        quote.symbol,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        quote.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(priceText(quote.lastPrice, roundTwoDp: round2)),
              Text(
                percentText(quote.changePercent),
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: added ? 'Added' : 'Add',
            onPressed: added ? null : () => onAdd(quote.symbol),
            icon: Icon(
              added ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              color: added
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.result, required this.onAdd});

  final SearchResult result;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final added = ref.watch(
      watchlistProvider.select((symbols) => symbols.contains(result.symbol)),
    );
    return ListTile(
      title: Text(
        result.symbol,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        result.name.isEmpty
            ? result.exchange
            : result.type.isEmpty
                ? result.name
                : '${result.name} · ${result.type}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: added ? 'Added' : 'Add',
        onPressed: added ? null : () => onAdd(result.symbol),
        icon: Icon(
          added ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
          color: added
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
