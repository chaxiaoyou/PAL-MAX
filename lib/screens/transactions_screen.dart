import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/position_ledger.dart';
import '../models/transaction.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/holding_editor_sheet.dart';
import '../widgets/transaction_editor_sheet.dart';

/// One position, and the trades behind it.
///
/// The ledger is the precise record; the position above it is what those trades
/// add up to. A hand-entered position has no trades yet, so the only action is
/// to convert it — selling shares the ledger never saw would otherwise be
/// silently ignored.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({
    super.key,
    required this.symbol,
    required this.name,
    required this.currency,
  });

  final String symbol;
  final String name;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(portfolioProvider).holdings;
    final transactions = ref.watch(transactionsProvider);
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    final ledger = ref.watch(ledgersProvider)[symbol];
    final holding = holdings.where((h) => h.symbol == symbol).firstOrNull;
    final rows = [
      for (final transaction in transactions.transactions)
        if (transaction.symbol == symbol) transaction,
    ]..sort((a, b) => b.tradedAt.compareTo(a.tradedAt));

    final shares = ledger?.shares ?? holding?.shares ?? 0;
    final averageCost = ledger?.averageCost ?? holding?.costPerShare ?? 0;
    final costBasis = shares * averageCost;
    final hasLedger = rows.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(symbol)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.fabInset,
        ),
        children: [
          _PositionCard(
            name: name,
            currency: currency,
            shares: shares,
            averageCost: averageCost,
            costBasis: costBasis,
            ledger: ledger,
            hasLedger: hasLedger,
            roundTwoDp: round2,
            onConvert: () async {
              if (holding == null) return;
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(transactionsProvider.notifier)
                  .openLedgerFor(holding);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Opening balance recorded. Add the trades from here on.',
                    ),
                  ),
                );
            },
            onEditManually: holding == null
                ? null
                : () => openHoldingEditor(context, existing: holding),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.sm),
            child: Text(
              hasLedger ? 'TRANSACTIONS · ${rows.length}' : 'TRANSACTIONS',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (!hasLedger)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                'Nothing recorded yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  indent: Space.gutter,
                  endIndent: Space.gutter,
                ),
              _TransactionRow(
                transaction: rows[index],
                currency: currency,
                roundTwoDp: round2,
                onTap: () => openTransactionEditor(
                  context,
                  symbol: symbol,
                  currency: currency,
                  existing: rows[index],
                  heldShares: shares,
                ),
              ),
            ],
        ],
      ),
      floatingActionButton: hasLedger
          ? FloatingActionButton.extended(
              onPressed: () => openTransactionEditor(
                context,
                symbol: symbol,
                currency: currency,
                heldShares: shares,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add transaction'),
            )
          : null,
    );
  }
}

/// Opens the trade editor and reports what happened.
Future<void> openTransactionEditor(
  BuildContext context, {
  required String symbol,
  required String currency,
  Transaction? existing,
  double heldShares = 0,
}) async {
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TransactionEditorSheet(
      symbol: symbol,
      currency: currency,
      existing: existing,
      heldShares: heldShares,
    ),
  );
  if (message == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.name,
    required this.currency,
    required this.shares,
    required this.averageCost,
    required this.costBasis,
    required this.ledger,
    required this.hasLedger,
    required this.roundTwoDp,
    required this.onConvert,
    required this.onEditManually,
  });

  final String name;
  final String currency;
  final double shares;
  final double averageCost;
  final double costBasis;
  final PositionLedger? ledger;
  final bool hasLedger;
  final bool roundTwoDp;
  final VoidCallback onConvert;

  /// `null` when there is no stored position to edit.
  final VoidCallback? onEditManually;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall;
    final realized = ledger?.realizedProfit ?? 0;
    final realizedColor = changeColor(
      context,
      realized > 0
          ? QuoteDirection.up
          : realized < 0
              ? QuoteDirection.down
              : QuoteDirection.flat,
    );

    return Card(
      child: Padding(
        padding: Space.cardContent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.isEmpty ? '—' : name, style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.md),
            Text('POSITION', style: labelStyle),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  shares > 0 ? '${sharesText(shares)} shares' : 'No shares',
                  style: theme.textTheme.headlineSmall,
                ),
                if (shares > 0)
                  Text(
                    'avg ${moneyText(averageCost, currency, roundTwoDp: roundTwoDp)}'
                    '  ·  cost basis '
                    '${moneyText(costBasis, currency, roundTwoDp: roundTwoDp)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            if (ledger != null && ledger!.hasRealized) ...[
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Realized ${signedMoney(realized, currency, roundTwoDp: roundTwoDp)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: realizedColor,
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  Text(
                    ledger!.sales.length == 1
                        ? 'from 1 sale'
                        : 'from ${ledger!.sales.length} sales',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (ledger != null && ledger!.unmatchedShares > 0) ...[
              const SizedBox(height: Space.sm),
              Text(
                '${sharesText(ledger!.unmatchedShares)} shares were sold that '
                'this ledger has no record of buying, so they are not counted.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (!hasLedger) ...[
              const SizedBox(height: Space.md),
              Text(
                'This position was entered by hand. Track buys and sells '
                'instead and the shares and average cost above become the '
                'opening balance.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.md),
              FilledButton.icon(
                onPressed: onEditManually,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit manually'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: shares > 0 ? onConvert : null,
                  child: const Text('Track buys and sells instead'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.currency,
    required this.roundTwoDp,
    required this.onTap,
  });

  final Transaction transaction;
  final String currency;
  final bool roundTwoDp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuy = transaction.type == TransactionKind.buy;
    final date = transaction.tradedAt.toLocal();
    final gross = transaction.shares * transaction.pricePerShare;
    // Cash that moved: what the buy cost, or what the sell brought in. The
    // Buy/Sell label above says which direction it went.
    final cash = isBuy ? gross + transaction.fee : gross - transaction.fee;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.md,
          Space.sm,
          Space.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction.type.label}  ·  '
                    '${date.year}-${two(date.month)}-${two(date.day)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    '${sharesText(transaction.shares)} @ '
                    '${moneyText(transaction.pricePerShare, currency, roundTwoDp: roundTwoDp)}'
                    '${transaction.fee == 0 ? '' : '  ·  fee ${moneyText(transaction.fee, currency, roundTwoDp: roundTwoDp)}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (transaction.note.isNotEmpty) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      transaction.note,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            Text(
              moneyText(cash, currency, roundTwoDp: roundTwoDp),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: tabularFigures,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
