import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dividend_income.dart';
import '../models/holding.dart';
import '../models/portfolio_math.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/holding_editor_sheet.dart';
import 'transactions_screen.dart';

/// Portfolio tab: the value of everything held, the profit or loss against the
/// user's own cost basis, and each position priced with the latest quote.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  Future<void> _openEditor([Holding? holding]) async {
    await openHoldingEditor(context, existing: holding);
  }

  void _openLedger(HoldingPerformance position) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionsScreen(
          symbol: position.symbol,
          name: position.name,
          currency: position.currency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(portfolioSummaryProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, summary),
            Expanded(child: _buildContent(context, summary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PortfolioSummary summary) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  summary.positionCount == 0
                      ? 'Track what you own'
                      : '${summary.positionCount} '
                          '${summary.positionCount == 1 ? 'holding' : 'holdings'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Add holding',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, PortfolioSummary summary) {
    final holdings = ref.watch(portfolioProvider);
    final board = ref.watch(quoteBoardProvider);
    final dividendState = ref.watch(dividendProvider);
    final dividends = ref.watch(dividendSummaryProvider);
    if (holdings.loading && holdings.holdings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (holdings.holdings.isEmpty) {
      return _buildEmptyState(context);
    }
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    final dividendBySymbol = {
      for (final income in dividends.incomes) income.symbol: income,
    };
    return RefreshIndicator(
      onRefresh: () => ref.read(quoteBoardProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _SummaryCard(
              summary: summary,
              roundTwoDp: round2,
              lastFetch: board.lastFetch,
              fetching: board.fetching,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _DividendCard(
              summary: dividends,
              state: dividendState,
              currency: summary.primaryCurrency,
              roundTwoDp: round2,
              onRetry: () => ref.read(dividendProvider.notifier).retryFailed(),
            ),
          ),
          if (board.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ErrorBanner(
                message: board.error!,
                onRetry: () => ref.read(quoteBoardProvider.notifier).refresh(),
              ),
            ),
          if (summary.unpricedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                summary.unpricedCount == 1
                    ? '1 holding has no live quote and is left out of the totals.'
                    : '${summary.unpricedCount} holdings have no live quote and '
                        'are left out of the totals.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Text(
              'HOLDINGS · ${summary.positionCount}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
          for (var index = 0; index < summary.positions.length; index++) ...[
            if (index > 0)
              const Divider(height: 1, indent: 20, endIndent: 20),
            _HoldingRow(
              position: summary.positions[index],
              roundTwoDp: round2,
              dividend: dividendBySymbol[summary.positions[index].symbol],
              onTap: () => _openLedger(summary.positions[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'No holdings yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add what you own and the app tracks value and profit or loss '
              'against your cost basis.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a holding'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one focal element of the tab: what the portfolio is worth, with the
/// return against the user's own cost basis directly under it.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.roundTwoDp,
    required this.lastFetch,
    required this.fetching,
  });

  final PortfolioSummary summary;
  final bool roundTwoDp;
  final DateTime? lastFetch;
  final bool fetching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = summary.primaryTotals;
    if (totals == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Text(
            'Waiting for the first quote to value these holdings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final currency = totals.currency;
    final profitPercent = totals.profitPercent;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    final statStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: tabularFigures,
    );
    final profitColor = changeColor(
      context,
      totals.profit > 0
          ? QuoteDirection.up
          : totals.profit < 0
              ? QuoteDirection.down
              : QuoteDirection.flat,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PORTFOLIO VALUE', style: labelStyle),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                moneyText(totals.marketValue, currency, roundTwoDp: roundTwoDp),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Wrap, not Row: a large portfolio on a narrow screen (or a large
            // system text scale) pushes "total return" onto its own line
            // instead of overflowing the card.
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  signedMoney(totals.profit, currency, roundTwoDp: roundTwoDp),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: profitColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: tabularFigures,
                  ),
                ),
                if (profitPercent != null)
                  Text(
                    percentText(profitPercent),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                Text(
                  'total return',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COST BASIS', style: labelStyle),
                      const SizedBox(height: 3),
                      Text(
                        moneyText(
                          totals.costBasis,
                          currency,
                          roundTwoDp: roundTwoDp,
                        ),
                        style: statStyle,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TODAY', style: labelStyle),
                      const SizedBox(height: 3),
                      Text(
                        totals.dayChange == 0
                            ? '--'
                            : '${signedMoney(totals.dayChange, currency, roundTwoDp: roundTwoDp)}'
                                '${totals.dayChangePercent == null ? '' : ' (${percentText(totals.dayChangePercent!)})'}',
                        style: statStyle?.copyWith(
                          color: totals.dayChange == 0
                              ? theme.colorScheme.onSurfaceVariant
                              : changeColor(
                                  context,
                                  totals.dayChange > 0
                                      ? QuoteDirection.up
                                      : QuoteDirection.down,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary.hasMultipleCurrencies) ...[
              const SizedBox(height: 14),
              Text(
                'Other currencies are totalled separately',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              for (final code in summary.orderedCurrencies.skip(1))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$code  ${moneyText(summary.totalsByCurrency[code]!.marketValue, code, roundTwoDp: roundTwoDp)}'
                    '  ·  ${signedMoney(summary.totalsByCurrency[code]!.profit, code, roundTwoDp: roundTwoDp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
            ],
            if (summary.hasRealized) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('REALIZED', style: labelStyle),
                  Text(
                    signedMoney(
                      summary.realizedFor(currency),
                      currency,
                      roundTwoDp: roundTwoDp,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: changeColor(
                        context,
                        summary.realizedFor(currency) > 0
                            ? QuoteDirection.up
                            : summary.realizedFor(currency) < 0
                                ? QuoteDirection.down
                                : QuoteDirection.flat,
                      ),
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  Text(
                    summary.realizedSalesCount == 1
                        ? 'from 1 sale'
                        : 'from ${summary.realizedSalesCount} sales',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              fetching
                  ? 'Updating quotes…'
                  : lastFetch == null
                      ? 'Quotes by Yahoo Finance'
                      : 'Updated ${hhMm(lastFetch!)} · quotes by Yahoo Finance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing dividend cash and what it yields against the user's own cost basis.
/// A deliberately lower tier than the portfolio value: this is context for the
/// holdings, not the reason the screen exists.
class _DividendCard extends StatelessWidget {
  const _DividendCard({
    required this.summary,
    required this.state,
    required this.currency,
    required this.roundTwoDp,
    required this.onRetry,
  });

  final DividendSummary summary;
  final DividendState state;

  /// The portfolio's headline currency, so this card and the total above it
  /// are never read in different currencies.
  final String? currency;
  final bool roundTwoDp;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = currency ?? 'USD';
    final loading = state.loading && !summary.hasAny;
    final trailing = summary.trailingFor(code);
    final yieldOnCost = summary.yieldOnCost(code);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    final otherCurrencies = [
      for (final entry in summary.trailingByCurrency.entries)
        if (entry.key != code && entry.value > 0) entry.key,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DIVIDEND INCOME · 12 MO', style: labelStyle),
            const SizedBox(height: 6),
            if (loading)
              Text(
                'Loading dividend history…',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              // Wrap, not Row: a large total on a narrow screen moves the
              // yield onto its own line instead of overflowing the card.
              Wrap(
                spacing: 10,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    moneyText(trailing, code, roundTwoDp: roundTwoDp),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  if (yieldOnCost != null)
                    Text(
                      '${percentText(yieldOnCost, signed: false)} yield on cost',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              _note(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (otherCurrencies.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final other in otherCurrencies)
                Text(
                  '$other  ${moneyText(summary.trailingFor(other), other, roundTwoDp: roundTwoDp)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: tabularFigures,
                  ),
                ),
            ],
            if (state.failed.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.failed.length == 1
                          ? 'Dividend history unavailable for 1 holding'
                          : 'Dividend history unavailable for '
                              '${state.failed.length} holdings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Says which of the two ways the figures were produced. A ledger knows the
  /// share count on each payment date; a hand-entered position does not.
  String _note() {
    if (!summary.hasAny) return 'No dividends paid in the last twelve months.';
    if (summary.estimatedCount == 0) {
      return 'Credited on the shares you actually held at each payment date.';
    }
    if (summary.estimatedCount == summary.payingCount) {
      return 'Estimated from the shares you hold today, so a position that '
          'changed size during the year is approximate.';
    }
    return 'Positions without transactions are estimated from the shares you '
        'hold today.';
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.position,
    required this.roundTwoDp,
    required this.onTap,
    this.dividend,
  });

  final HoldingPerformance position;
  final bool roundTwoDp;
  final VoidCallback onTap;

  /// Trailing dividend cash for this position, when its history is known.
  final DividendIncome? dividend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priced = position.hasQuote;
    final closed = position.isClosed;
    final pays = dividend?.isPaying ?? false;
    final meta = StringBuffer();
    if (closed) {
      meta.write('Closed');
    } else {
      meta
        ..write(sharesText(position.shares))
        ..write(' @ ')
        ..write(
          moneyText(
            position.costPerShare,
            position.currency,
            roundTwoDp: roundTwoDp,
          ),
        );
    }
    if (pays) {
      meta
        ..write('  ·  ')
        ..write(
          moneyText(
            dividend!.trailingAmount,
            position.currency,
            roundTwoDp: roundTwoDp,
          ),
        )
        ..write('/yr');
    }
    final profitPercent = position.profitPercent;
    final profitColor = changeColor(
      context,
      position.profit > 0
          ? QuoteDirection.up
          : position.profit < 0
              ? QuoteDirection.down
              : QuoteDirection.flat,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    position.name.isEmpty ? '—' : position.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // A closed position has no market value left to show; what it
                // actually produced is the realised P/L.
                if (closed) ...[
                  Text(
                    signedMoney(
                      position.ledger!.realizedProfit,
                      position.currency,
                      roundTwoDp: roundTwoDp,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'realized',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  Text(
                    priced
                        ? moneyText(
                            position.marketValue,
                            position.currency,
                            roundTwoDp: roundTwoDp,
                          )
                        : '--',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priced
                        ? signedMoney(
                            position.profit,
                            position.currency,
                            roundTwoDp: roundTwoDp,
                          )
                        : '--',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: priced
                          ? profitColor
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priced
                        ? (profitPercent == null
                            ? '—'
                            : percentText(profitPercent))
                        : 'no quote',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: priced
                          ? profitColor
                          : theme.colorScheme.onSurfaceVariant,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ],
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
