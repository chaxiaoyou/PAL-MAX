import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_alert.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/alert_editor_sheet.dart';

/// Every price level being watched, and the honest limits of how they fire.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertsProvider.notifier).refreshPermission();
    });
  }

  Future<void> _add(PortfolioSymbol? symbol) async {
    final picked = symbol ?? await showModalBottomSheet<PortfolioSymbol>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _SymbolPickerSheet(),
        );
    if (picked == null || !mounted) return;
    await openAlertEditor(
      context,
      symbol: picked.symbol,
      name: picked.name,
      currency: picked.currency,
      currentPrice: picked.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertsProvider);
    final theme = Theme.of(context);
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    final quotes = ref.watch(quoteBoardProvider).quotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Price alerts')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                if (!state.notificationsAllowed)
                  _PermissionBanner(
                    onAllow: () =>
                        ref.read(alertsProvider.notifier).requestPermission(),
                  ),
                if (state.alerts.isEmpty)
                  _EmptyState(onAdd: () => _add(null))
                else ...[
                  for (var index = 0; index < state.alerts.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, indent: 20, endIndent: 20),
                    _AlertRow(
                      alert: state.alerts[index],
                      price: quotes[state.alerts[index].symbol]?.lastPrice,
                      roundTwoDp: round2,
                      onToggle: (value) => ref
                          .read(alertsProvider.notifier)
                          .setEnabled(state.alerts[index], value),
                      onTap: () => openAlertEditor(
                        context,
                        symbol: state.alerts[index].symbol,
                        name: state.alerts[index].name,
                        currency: state.alerts[index].currency,
                        currentPrice:
                            quotes[state.alerts[index].symbol]?.lastPrice,
                        existing: state.alerts[index],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _scheduleNote(state),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: state.backgroundReady
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: state.alerts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add alert'),
            ),
    );
  }

  /// Says what actually happens, including when the periodic check could not be
  /// registered: a silent failure here would look like working background
  /// alerts that never fire.
  String _scheduleNote(AlertsState state) {
    if (state.enabledCount == 0) {
      return 'Alerts are checked while the app is running.';
    }
    if (!state.backgroundReady) {
      return 'Alerts are checked while the app is running. A level crossed '
          'while the app is closed is reported the next time you open it.';
    }
    return 'Checked while the app is running, and roughly every 15 minutes by '
        'Android when it is closed — the system decides the exact timing and '
        'can delay it in battery saver mode.';
  }
}

/// A symbol an alert can be created for.
class PortfolioSymbol {
  const PortfolioSymbol({
    required this.symbol,
    required this.name,
    required this.currency,
    this.price,
  });

  final String symbol;
  final String name;
  final String currency;
  final double? price;
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.price,
    required this.roundTwoDp,
    required this.onToggle,
    required this.onTap,
  });

  final PriceAlert alert;
  final double? price;
  final bool roundTwoDp;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final triggered = alert.triggeredAt;
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
                    alert.symbol,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${alert.name.isEmpty ? '' : '${alert.name} · '}'
                    '${alert.side.phrase} '
                    '${moneyText(alert.threshold, alert.currency, roundTwoDp: roundTwoDp)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (price != null)
                        'now ${moneyText(price!, alert.currency, roundTwoDp: roundTwoDp)}',
                      if (triggered != null)
                        'last fired ${triggered.toLocal().year}-'
                            '${two(triggered.toLocal().month)}-'
                            '${two(triggered.toLocal().day)}',
                    ].join('  ·  '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: alert.enabled,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notifications are blocked, so alerts stay silent. Allow them '
                'in system settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: onAllow, child: const Text('Allow')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'No alerts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a price level and the app tells you when the price crosses '
            'it — not while it merely sits there.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add alert'),
          ),
        ],
      ),
    );
  }
}

/// Picks from what the user already follows, rather than asking them to type a
/// symbol here: alerts are set from a price, and these are the prices the app
/// already has.
class _SymbolPickerSheet extends ConsumerWidget {
  const _SymbolPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final round2 = ref.watch(appPrefsProvider).roundTwoDp;
    final watchlist = ref.watch(watchlistProvider).symbols;
    final holdings = ref.watch(portfolioProvider).holdings;
    final quotes = ref.watch(quoteBoardProvider).quotes;

    final seen = <String>{};
    final symbols = <PortfolioSymbol>[];
    for (final symbol in watchlist) {
      if (!seen.add(symbol)) continue;
      final quote = quotes[symbol];
      symbols.add(
        PortfolioSymbol(
          symbol: symbol,
          name: quote?.name ?? '',
          currency: quote?.currency ?? 'USD',
          price: quote?.lastPrice,
        ),
      );
    }
    for (final holding in holdings) {
      if (!seen.add(holding.symbol)) continue;
      final quote = quotes[holding.symbol];
      symbols.add(
        PortfolioSymbol(
          symbol: holding.symbol,
          name: holding.name,
          currency: quote?.currency ?? holding.currency,
          price: quote?.lastPrice,
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Watch a price',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: symbols.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = symbols[index];
                return ListTile(
                  title: Text(
                    entry.symbol,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: entry.price == null
                      ? null
                      : Text(moneyText(entry.price!, entry.currency,
                          roundTwoDp: round2)),
                  onTap: () => Navigator.of(context).pop(entry),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
