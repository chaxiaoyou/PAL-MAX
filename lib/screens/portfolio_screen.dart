import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/portfolio_store.dart';
import '../domain/position.dart';
import '../domain/transaction.dart';
import '../l10n/l10n.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Allocation bar palette. Deliberately not the brand blue: segments sit next to
/// each other and need to be told apart, not to match.
const _sliceColors = <Color>[
  Color(0xff2f6fd0),
  Color(0xff17a2a2),
  Color(0xffe08c2a),
  Color(0xff8b5cf6),
  Color(0xffd95f7a),
  Color(0xff5f8f3f),
  Color(0xff5c6b8a),
];

Color sliceColor(int index) => _sliceColors[index % _sliceColors.length];

/// Portfolio dashboard: totals, allocation and the position table.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final transactions = ref.watch(transactionsProvider);
    final ledger = ref.watch(ledgerProvider);
    final valuation = ref.watch(portfolioValuationProvider);
    final prices = ref.watch(portfolioPricesProvider);
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;

    if (transactions.isEmpty) {
      return _EmptyPortfolio(onAdd: () => _addTransaction(context, ref));
    }

    Future<void> refresh() async {
      // `refresh` returns the new future, so it has to be awaited explicitly.
      final refreshed = ref.refresh(portfolioPricesProvider.future);
      await refreshed;
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(kGutter, kSpace3, kGutter, kSpace6),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.portfolioTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.portfolioRefresh,
                onPressed: prices.isLoading ? null : refresh,
                icon: prices.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: l10n.portfolioAddTransaction,
                onPressed: () => _addTransaction(context, ref),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: kSpace2),
          _TotalsCard(valuation: valuation, roundTwoDp: round2),
          if (valuation.isPartial) ...[
            const SizedBox(height: kSpace3),
            _Notice(
              icon: Icons.help_outline_rounded,
              message: l10n.portfolioPartialData,
              detail: l10n.portfolioMissingSymbols(
                valuation.missingPrices.join(', '),
              ),
            ),
          ],
          for (final warning in ledger.warnings) ...[
            const SizedBox(height: kSpace3),
            _Notice(
              icon: Icons.warning_amber_rounded,
              message: l10n.warningOversell(
                warning.symbol,
                fmtNum(warning.quantity),
              ),
              tone: theme.colorScheme.error,
            ),
          ],
          if (valuation.slices.isNotEmpty) ...[
            const SizedBox(height: kSpace5),
            _AllocationCard(valuation: valuation, roundTwoDp: round2),
          ],
          const SizedBox(height: kSpace5),
          _PositionsTable(
            ledger: ledger,
            prices: prices.valueOrNull ?? const {},
            totalValue: valuation.marketValue,
            roundTwoDp: round2,
          ),
          const SizedBox(height: kSpace4),
        ],
      ),
    );
  }
}

/// Records a buy or sell. Kept as a sheet: it is a form with four fields and no
/// navigation of its own.
Future<void> _addTransaction(BuildContext context, WidgetRef ref) async {
  final draft = await showModalBottomSheet<_TransactionDraft>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _TransactionSheet(),
  );
  if (draft == null) return;
  await ref.read(transactionsProvider.notifier).add(
        Transaction(
          id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
          symbol: draft.symbol,
          side: draft.side,
          quantity: draft.quantity,
          price: draft.price,
          fees: draft.fees,
          executedAt: draft.executedAt,
        ),
      );
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.valuation, required this.roundTwoDp});

  final PortfolioValuation valuation;
  final bool roundTwoDp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpace4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.portfolioTotalValue,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currencySymbol('MXN')}${priceText(valuation.marketValue, roundTwoDp: roundTwoDp)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: kTabular,
            ),
          ),
          const SizedBox(height: kSpace2),
          Text(
            '${signedAmount(valuation.dayChangeValue, roundTwoDp: roundTwoDp)}'
            '  ·  ${l10n.portfolioToday}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: changeColor(
                context,
                valuation.dayChangeValue > 0
                    ? QuoteDirection.up
                    : valuation.dayChangeValue < 0
                        ? QuoteDirection.down
                        : QuoteDirection.flat,
              ),
              fontWeight: FontWeight.w700,
              fontFeatures: kTabular,
            ),
          ),
          const SizedBox(height: kSpace4),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.portfolioInvested,
                  value: priceText(valuation.costBasis, roundTwoDp: roundTwoDp),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: l10n.portfolioUnrealized,
                  value: signedAmount(
                    valuation.unrealizedPnl,
                    roundTwoDp: roundTwoDp,
                  ),
                  detail: percentText(valuation.unrealizedPct),
                  tone: valuation.unrealizedPnl,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: l10n.portfolioRealized,
                  value: signedAmount(
                    valuation.realizedPnl,
                    roundTwoDp: roundTwoDp,
                  ),
                  tone: valuation.realizedPnl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.detail,
    this.tone,
  });

  final String label;
  final String value;
  final String? detail;

  /// When set, a negative value is tinted as a loss and a positive one as a
  /// gain; null keeps the number neutral (cost basis is not a result).
  final double? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == null
        ? theme.colorScheme.onSurface
        : changeColor(
            context,
            tone! > 0
                ? QuoteDirection.up
                : tone! < 0
                    ? QuoteDirection.down
                    : QuoteDirection.flat,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: kTabular,
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
      ],
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.valuation, required this.roundTwoDp});

  final PortfolioValuation valuation;
  final bool roundTwoDp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final slices = valuation.slices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              l10n.portfolioAllocation,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: kSpace2),
            Text(
              l10n.portfolioHoldingCount(slices.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpace2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (var index = 0; index < slices.length; index++)
                  Expanded(
                    flex: (slices[index].weight * 10).round().clamp(1, 100000),
                    child: ColoredBox(color: sliceColor(index)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kSpace3),
        for (var index = 0; index < slices.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: sliceColor(index),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: kSpace2),
                Expanded(
                  child: Text(
                    slices[index].symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  priceText(
                    slices[index].marketValue,
                    roundTwoDp: roundTwoDp,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: kTabular,
                  ),
                ),
                const SizedBox(width: kSpace3),
                SizedBox(
                  width: 52,
                  child: Text(
                    percentText(slices[index].weight, signed: false),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabular,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PositionsTable extends StatelessWidget {
  const _PositionsTable({
    required this.ledger,
    required this.prices,
    required this.totalValue,
    required this.roundTwoDp,
  });

  final LedgerResult ledger;
  final Map<String, PriceSnapshot> prices;

  /// Securities value across priced positions, used as the weight denominator.
  final double totalValue;
  final bool roundTwoDp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final positions = ledger.openPositions.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: kSpace2),
          child: Text(
            l10n.portfolioPositions,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(
                  labels: [
                    l10n.columnSymbol,
                    l10n.columnQuantity,
                    l10n.columnAverageCost,
                    l10n.columnPrice,
                    l10n.columnMarketValue,
                    l10n.columnPnl,
                    l10n.columnWeight,
                  ],
                ),
                for (final position in positions)
                  _PositionRow(
                    position: position,
                    snapshot: prices[position.symbol],
                    marketValue: prices[position.symbol] == null
                        ? null
                        : position.quantity *
                            prices[position.symbol]!.price *
                            prices[position.symbol]!.fxRate,
                    totalValue: totalValue,
                    roundTwoDp: roundTwoDp,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

const _colSymbol = 104.0;
const _colNumber = 88.0;
const _colWide = 104.0;
const _colWeight = 64.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const widths = [
      _colSymbol,
      _colNumber,
      _colNumber,
      _colNumber,
      _colWide,
      _colWide,
      _colWeight,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            SizedBox(
              width: widths[index],
              child: Text(
                labels[index],
                textAlign: index == 0 ? TextAlign.left : TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.position,
    required this.snapshot,
    required this.marketValue,
    required this.totalValue,
    required this.roundTwoDp,
  });

  final Position position;
  final PriceSnapshot? snapshot;
  final double? marketValue;
  final double totalValue;
  final bool roundTwoDp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = snapshot;
    final pnl = marketValue == null ? null : marketValue! - position.costBasis;

    TextStyle? numberStyle(double? tone) => theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontFeatures: kTabular,
          color: tone == null
              ? theme.colorScheme.onSurface
              : changeColor(
                  context,
                  tone > 0
                      ? QuoteDirection.up
                      : tone < 0
                          ? QuoteDirection.down
                          : QuoteDirection.flat,
                ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colSymbol,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data == null ? '—' : data.currency,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _colNumber,
            child: Text(
              fmtNum(position.quantity),
              textAlign: TextAlign.right,
              style: numberStyle(null),
            ),
          ),
          SizedBox(
            width: _colNumber,
            child: Text(
              priceText(position.averageCost, roundTwoDp: roundTwoDp),
              textAlign: TextAlign.right,
              style: numberStyle(null),
            ),
          ),
          SizedBox(
            width: _colNumber,
            child: Text(
              data == null ? '—' : priceText(data.price, roundTwoDp: roundTwoDp),
              textAlign: TextAlign.right,
              style: numberStyle(null),
            ),
          ),
          SizedBox(
            width: _colWide,
            child: Text(
              marketValue == null
                  ? '—'
                  : priceText(marketValue!, roundTwoDp: roundTwoDp),
              textAlign: TextAlign.right,
              style: numberStyle(null),
            ),
          ),
          SizedBox(
            width: _colWide,
            child: Text(
              pnl == null
                  ? '—'
                  : '${signedAmount(pnl, roundTwoDp: roundTwoDp)}\n'
                      '${percentText(position.costBasis == 0 ? 0 : pnl / position.costBasis * 100)}',
              textAlign: TextAlign.right,
              style: numberStyle(pnl),
            ),
          ),
          SizedBox(
            width: _colWeight,
            child: Text(
              marketValue == null || totalValue <= 0
                  ? '—'
                  : percentText(marketValue! / totalValue * 100, signed: false),
              textAlign: TextAlign.right,
              style: numberStyle(null),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.detail,
    this.tone,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpace3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusControl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: kSpace2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpace6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.donut_large_rounded,
              size: 52,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: kSpace3),
            Text(
              l10n.portfolioEmptyTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.portfolioEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: kSpace4),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.portfolioAddTransaction),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDraft {
  const _TransactionDraft({
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.fees,
    required this.executedAt,
  });

  final String symbol;
  final TradeSide side;
  final double quantity;
  final double price;
  final double fees;
  final DateTime executedAt;
}

class _TransactionSheet extends StatefulWidget {
  const _TransactionSheet();

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _symbolCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  TradeSide _side = TradeSide.buy;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _feesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: kSpace4,
        right: kSpace4,
        top: kSpace4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + kSpace4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.portfolioAddTransaction,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: kSpace3),
          SegmentedButton<TradeSide>(
            segments: [
              ButtonSegment(value: TradeSide.buy, label: Text(l10n.segmentLong)),
              ButtonSegment(
                value: TradeSide.sell,
                label: Text(l10n.segmentShort),
              ),
            ],
            selected: {_side},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _side = selection.first),
          ),
          const SizedBox(height: kSpace3),
          TextField(
            controller: _symbolCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.alertSymbol),
          ),
          const SizedBox(height: kSpace3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.columnQuantity),
                ),
              ),
              const SizedBox(width: kSpace3),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.columnPrice),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpace3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _feesCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.resultFees),
                ),
              ),
              const SizedBox(width: kSpace3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(fmtDate(_date)),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpace4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.actionCancel),
                ),
              ),
              const SizedBox(width: kSpace3),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.actionSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    final quantity = parseNum(_qtyCtrl.text);
    final price = parseNum(_priceCtrl.text);
    if (symbol.isEmpty || quantity <= 0 || price <= 0) return;
    Navigator.pop(
      context,
      _TransactionDraft(
        symbol: symbol,
        side: _side,
        quantity: quantity,
        price: price,
        fees: parseNum(_feesCtrl.text),
        executedAt: _date,
      ),
    );
  }
}
