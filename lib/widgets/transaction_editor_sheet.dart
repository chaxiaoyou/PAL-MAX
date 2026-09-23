import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/providers.dart';
import '../utils/format.dart';

/// Records one buy or sell. Pops with a status message for the caller, or `null`
/// when dismissed.
class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({
    super.key,
    required this.symbol,
    required this.currency,
    this.existing,
    this.heldShares = 0,
  });

  final String symbol;
  final String currency;

  /// `null` when adding.
  final Transaction? existing;

  /// Shares the ledger holds now, used to flag a sell that exceeds them.
  final double heldShares;

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  final _feeController = TextEditingController();

  late TransactionKind _kind = widget.existing?.type ?? TransactionKind.buy;
  late DateTime _tradedAt = widget.existing?.tradedAt ?? DateTime.now();
  bool _saving = false;
  String? _sharesError;
  String? _priceError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _sharesController.text = sharesText(existing.shares);
      _priceController.text =
          priceText(existing.pricePerShare, roundTwoDp: false);
      if (existing.fee != 0) {
        _feeController.text = priceText(existing.fee, roundTwoDp: false);
      }
    }
  }

  @override
  void dispose() {
    _sharesController.dispose();
    _priceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) {
    final cleaned = controller.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Shares the sell exceeds, if any. The ledger refuses to sell what it does
  /// not hold, so telling the user now beats a silently clamped row later.
  double get _oversold {
    if (_kind != TransactionKind.sell) return 0;
    final shares = _parse(_sharesController) ?? 0;
    final excess = shares - widget.heldShares;
    return excess > 0 ? excess : 0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tradedAt,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _tradedAt = picked);
  }

  Future<void> _save() async {
    final shares = _parse(_sharesController);
    final price = _parse(_priceController);
    final fee = _parse(_feeController) ?? 0;
    setState(() {
      _sharesError =
          (shares == null || shares <= 0) ? 'Enter how many shares' : null;
      _priceError =
          (price == null || price < 0) ? 'Enter the price per share' : null;
    });
    if (_sharesError != null || _priceError != null) return;

    setState(() => _saving = true);
    await ref.read(transactionsProvider.notifier).save(
          TransactionDraft(
            symbol: widget.symbol,
            kind: _kind,
            shares: shares!,
            pricePerShare: price!,
            fee: fee,
            tradedAt: _tradedAt,
            currency: widget.currency,
            note: widget.existing?.note ?? '',
          ),
          existing: widget.existing,
        );
    if (!mounted) return;
    Navigator.of(context).pop(
      '${_kind.label} of ${sharesText(shares)} ${widget.symbol} saved',
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction'),
        content: const Text(
          'This changes the position this ledger describes. It cannot be undone.',
        ),
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
    await ref.read(transactionsProvider.notifier).remove(widget.existing!);
    if (!mounted) return;
    Navigator.of(context).pop('Transaction deleted');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit transaction' : 'Add transaction',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.symbol,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SegmentedButton<TransactionKind>(
              segments: [
                for (final kind in TransactionKind.values)
                  ButtonSegment<TransactionKind>(
                    value: kind,
                    label: Text(kind.label),
                  ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _kind = selection.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: _decoration(
                theme,
                label: 'Shares',
                hint: '10',
                error: _sharesError,
              ),
            ),
            if (_oversold > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You hold ${sharesText(widget.heldShares)} shares. '
                  'The extra ${sharesText(_oversold)} will not be counted.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: _decoration(
                theme,
                label: 'Price per share',
                hint: '0.00',
                error: _priceError,
                prefix: currencySymbol(widget.currency),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: _decoration(
                theme,
                label: 'Fees (optional)',
                hint: '0.00',
                error: null,
                prefix: currencySymbol(widget.currency),
              ),
            ),
            const SizedBox(height: 18),
            Text('TRADE DATE', style: labelStyle),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text(_formatDate(_tradedAt)),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Add transaction'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _saving ? null : _confirmDelete,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Delete transaction'),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  InputDecoration _decoration(
    ThemeData theme, {
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
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
