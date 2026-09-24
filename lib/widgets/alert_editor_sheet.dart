import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_alert.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Opens the alert editor and reports what happened.
Future<void> openAlertEditor(
  BuildContext context, {
  required String symbol,
  required String name,
  required String currency,
  double? currentPrice,
  PriceAlert? existing,
}) async {
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AlertEditorSheet(
      symbol: symbol,
      name: name,
      currency: currency,
      currentPrice: currentPrice,
      existing: existing,
    ),
  );
  if (message == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Sets one price level to watch for [symbol].
class AlertEditorSheet extends ConsumerStatefulWidget {
  const AlertEditorSheet({
    super.key,
    required this.symbol,
    required this.name,
    required this.currency,
    this.currentPrice,
    this.existing,
  });

  final String symbol;
  final String name;
  final String currency;

  /// Latest price, used only as a hint for choosing a level.
  final double? currentPrice;

  final PriceAlert? existing;

  @override
  ConsumerState<AlertEditorSheet> createState() => _AlertEditorSheetState();
}

class _AlertEditorSheetState extends ConsumerState<AlertEditorSheet> {
  final _thresholdController = TextEditingController();
  late AlertDirection _direction =
      widget.existing?.side ?? AlertDirection.above;
  bool _saving = false;
  String? _thresholdError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _thresholdController.text = priceText(
        existing.threshold,
        roundTwoDp: false,
      );
    } else if (widget.currentPrice != null) {
      // Level alerts are almost always set just off the current price.
      _thresholdController.text = priceText(
        widget.currentPrice!,
        roundTwoDp: false,
      );
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cleaned = _thresholdController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final threshold = double.tryParse(cleaned);
    setState(() {
      _thresholdError =
          (threshold == null || threshold <= 0) ? 'Enter a price level' : null;
    });
    if (_thresholdError != null) return;

    setState(() => _saving = true);
    // Ask for notification permission at the moment the user first needs it,
    // not on launch.
    final allowed = await ref.read(alertsProvider.notifier).requestPermission();
    if (!mounted) return;
    await ref.read(alertsProvider.notifier).save(
          PriceAlertDraft(
            symbol: widget.symbol,
            name: widget.name,
            direction: _direction,
            threshold: threshold!,
            currency: widget.currency,
          ),
          existing: widget.existing,
        );
    if (!mounted) return;
    Navigator.of(context).pop(
      allowed
          ? '${widget.symbol} alert saved'
          : '${widget.symbol} alert saved · notifications are blocked in system settings',
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete alert'),
        content: Text('Stop watching ${widget.symbol}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(alertsProvider.notifier).remove(widget.existing!);
    if (!mounted) return;
    Navigator.of(context).pop('Alert deleted');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final price = widget.currentPrice;
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
                _isEditing ? 'Edit alert' : 'New price alert',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.xs),
              Text(
                widget.name.isEmpty
                    ? widget.symbol
                    : '${widget.symbol} · ${widget.name}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Space.xl),
              SegmentedButton<AlertDirection>(
                segments: [
                  for (final direction in AlertDirection.values)
                    ButtonSegment<AlertDirection>(
                      value: direction,
                      label: Text(direction.label),
                    ),
                ],
                selected: {_direction},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _direction = selection.first);
                },
              ),
              const SizedBox(height: Space.lg),
              TextField(
                controller: _thresholdController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Price level',
                  errorText: _thresholdError,
                  prefixText: currencySymbol(widget.currency),
                  helperText: price == null
                      ? 'Alerts fire when the price crosses this level.'
                      : 'Now ${moneyText(price, widget.currency)} · alerts fire '
                          'when the price crosses this level.',
                ),
              ),
              const SizedBox(height: Space.xxl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Create alert'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: Space.sm),
                TextButton(
                  onPressed: _saving ? null : _confirmDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Delete alert'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
