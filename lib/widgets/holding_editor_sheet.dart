import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/holding.dart';
import '../models/quote.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Opens the position editor as a sheet and reports what happened.
Future<void> openHoldingEditor(
  BuildContext context, {
  Holding? existing,
}) async {
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => HoldingEditorSheet(existing: existing),
  );
  if (message == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Records a position. In add mode the symbol is resolved through Yahoo symbol
/// search so the stored name and currency come from the instrument itself
/// instead of being typed by hand.
///
/// Pops with a status message for the caller to show, or `null` when dismissed.
class HoldingEditorSheet extends ConsumerStatefulWidget {
  const HoldingEditorSheet({super.key, this.existing});

  /// `null` when adding a new position.
  final Holding? existing;

  @override
  ConsumerState<HoldingEditorSheet> createState() => _HoldingEditorSheetState();
}

class _HoldingEditorSheetState extends ConsumerState<HoldingEditorSheet> {
  static const _currencies = <String>[
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CNY',
    'HKD',
    'CAD',
    'AUD',
    'CHF',
    'INR',
    'KRW',
    'TWD',
    'SGD',
    'BRL',
    'MXN',
    'ARS',
  ];

  final _searchController = TextEditingController();
  final _sharesController = TextEditingController();
  final _costController = TextEditingController();
  Timer? _debounce;

  List<SearchResult> _results = const [];
  bool _searching = false;

  String _symbol = '';
  String _name = '';
  String _currency = 'USD';
  double? _lastPrice;

  bool _saving = false;
  String? _symbolError;
  String? _sharesError;
  String? _costError;

  bool get _isEditing => widget.existing != null;

  /// The currency picker only appears when a live quote could not confirm the
  /// instrument's currency — no guessing silently in the background.
  bool get _needsCurrency =>
      _symbol.isNotEmpty && _lastPrice == null && !_resolvingQuote;
  bool _resolvingQuote = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _symbol = existing.symbol;
      _name = existing.name;
      _currency = existing.currency;
      _searchController.text = existing.symbol;
      _sharesController.text = sharesText(existing.shares);
      _costController.text = priceText(
        existing.costPerShare,
        roundTwoDp: false,
      );
      _resolveQuote(existing.symbol);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _sharesController.dispose();
    _costController.dispose();
    super.dispose();
  }

  /// Looks up the live quote for [symbol] to confirm name, currency and the
  /// current price shown as a reference while entering the cost basis.
  Future<void> _resolveQuote(String symbol) async {
    // Plain assignment, not setState: this also runs from initState (where a
    // rebuild is pointless) and callers that need a frame already schedule one.
    _resolvingQuote = true;
    try {
      final quotes = await ref.read(yahooApiProvider).fetchQuotes([symbol]);
      if (!mounted) return;
      final quote = quotes.isEmpty ? null : quotes.first;
      setState(() {
        _resolvingQuote = false;
        if (quote != null) {
          _lastPrice = quote.lastPrice;
          if (quote.currency.isNotEmpty) _currency = quote.currency;
          if (_name.isEmpty) _name = quote.name;
        }
      });
    } catch (error, stackTrace) {
      debugPrint('holding quote lookup failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _resolvingQuote = false);
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await ref.read(yahooApiProvider).search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (error, stackTrace) {
      debugPrint('holding symbol search failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
      });
    }
  }

  Future<void> _pick(SearchResult result) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _symbol = result.symbol;
      _name = result.name;
      _symbolError = null;
      _results = const [];
    });
    _searchController.text = result.symbol;
    await _resolveQuote(result.symbol);
  }

  /// Escape hatch for symbols search cannot resolve (offline, or a listing
  /// Yahoo does not index): record the typed symbol and pick the currency by
  /// hand, then let the quote catch up later.
  void _useTypedSymbol() {
    final raw = _searchController.text.trim().toUpperCase();
    if (raw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _symbol = raw;
      _name = _name.isEmpty ? raw : _name;
      _symbolError = null;
      _results = const [];
    });
  }

  double? _parseNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _save() async {
    final shares = _parseNumber(_sharesController.text);
    final cost = _parseNumber(_costController.text);
    setState(() {
      _symbolError = _symbol.isEmpty ? 'Pick a symbol first' : null;
      _sharesError = (shares == null || shares <= 0)
          ? 'Enter how many shares you hold'
          : null;
      _costError = (cost == null || cost < 0)
          ? 'Enter the average cost per share'
          : null;
    });
    if (_symbolError != null || _sharesError != null || _costError != null) {
      return;
    }

    setState(() => _saving = true);
    await ref.read(portfolioProvider.notifier).upsert(
          HoldingDraft(
            symbol: _symbol,
            name: _name,
            shares: shares!,
            costPerShare: cost!,
            currency: _currency,
          ),
        );
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(_isEditing ? '$_symbol updated' : '$_symbol added to your portfolio');
  }

  Future<void> _confirmDelete() async {
    final symbol = _symbol;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove holding'),
        content: Text('Remove $symbol from your portfolio?'),
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
    if (confirmed != true || !mounted) return;
    await ref.read(portfolioProvider.notifier).remove(symbol);
    if (!mounted) return;
    Navigator.of(context).pop('$symbol removed');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A scroll-controlled sheet is not height-limited by the framework, so
    // without this the form simply grows past the bottom of a short screen and
    // the save button becomes unreachable.
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * 0.9 - media.viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit holding' : 'Add holding',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.xs),
              Text(
                _isEditing
                    ? 'Update the share count or your average cost.'
                    : 'Your cost basis stays on this device.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Space.xl),
              if (_isEditing)
                _buildLockedSymbol(theme)
              else
                _buildSymbolField(theme),
              const SizedBox(height: Space.lg),
              _buildSharesField(),
              const SizedBox(height: Space.lg),
              _buildCostField(theme),
              if (_needsCurrency) ...[
                const SizedBox(height: Space.lg),
                _buildCurrencyField(),
              ],
              const SizedBox(height: Space.xxl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Add to portfolio'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: Space.sm),
                TextButton(
                  onPressed: _saving ? null : _confirmDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Remove holding'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedSymbol(ThemeData theme) {
    return _field(
      label: 'Symbol',
      child: Row(
        children: [
          Expanded(
            child: Text(
              _symbol,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_lastPrice != null)
            Text(
              priceText(_lastPrice!, roundTwoDp: false),
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildSymbolField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          textCapitalization: TextCapitalization.characters,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            labelText: 'Symbol',
            hintText: 'Search symbol or company (e.g. AAPL)',
            errorText: _symbolError,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        if (_resolvingQuote)
          const Padding(
            padding: EdgeInsets.only(top: Space.md),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_symbol.isNotEmpty && !_resolvingQuote) _buildResolvedRow(theme),
        if (_searching)
          const Padding(
            padding: EdgeInsets.only(top: Space.md),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: Space.gutter),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          result.symbol,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          result.name.isEmpty ? result.exchange : result.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _pick(result),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        if (!_searching &&
            _searchController.text.trim().isNotEmpty &&
            _symbol != _searchController.text.trim().toUpperCase())
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _useTypedSymbol,
              child: Text(
                'Use "${_searchController.text.trim().toUpperCase()}" as a symbol',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResolvedRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              _name.isEmpty ? _symbol : '$_name · $_currency',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (_lastPrice != null)
            Text(
              'Current ${priceText(_lastPrice!, roundTwoDp: false)}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildSharesField() {
    return TextField(
      controller: _sharesController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: _inputDecoration(
        label: 'Shares',
        hint: '10',
        error: _sharesError,
      ),
    );
  }

  Widget _buildCostField(ThemeData theme) {
    return TextField(
      controller: _costController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: _inputDecoration(
        label: 'Average cost per share',
        hint: '0.00',
        error: _costError,
        prefix: _lastPrice == null ? null : currencySymbol(_currency),
      ),
    );
  }

  Widget _buildCurrencyField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_currency),
          initialValue: _currency,
          decoration: _inputDecoration(
            label: 'Currency',
            hint: '',
            error: null,
          ),
          items: [
            for (final code in _currencies)
              DropdownMenuItem<String>(
                value: code,
                child: Text('$code · ${currencySymbol(code)}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _currency = value);
          },
        ),
        const SizedBox(height: Space.sm),
        Text(
          'No live quote for this symbol yet, so the currency cannot be '
          'confirmed automatically.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required String? error,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      prefixText: prefix,
    );
  }

  Widget _field({required String label, required Widget child}) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: child,
    );
  }
}
