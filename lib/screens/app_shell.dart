import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/portfolio_store.dart';
import '../domain/alert.dart';
import '../domain/position.dart';
import '../l10n/l10n.dart';
import '../services/alert_notifier.dart';
import '../services/alert_dispatcher.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';
import 'home_screen.dart';
import 'portfolio_screen.dart';

/// Shell for the portfolio product.
///
/// Top navigation instead of the bottom bar, because the first tab is a
/// dashboard you scroll through rather than a feed you sit in — and because
/// the market list is now one section among three, not the app itself.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  late final AlertDispatcher _dispatcher = AlertDispatcher(
    notifier: ref.read(alertNotifierProvider),
    markTriggered: (alert, at) =>
        ref.read(alertsProvider.notifier).markTriggered(alert, at),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Map<String, PriceSnapshot>>>(
      portfolioPricesProvider,
      (previous, next) {
        final prices = next.valueOrNull;
        if (prices == null || prices.isEmpty) return;
        _dispatchAlerts(prices);
      },
    );

    final l10n = context.l10n;
    final tabs = <_ShellTab>[
      _ShellTab(
        label: l10n.navPortfolio,
        icon: Icons.donut_large_rounded,
        body: const PortfolioScreen(),
      ),
      _ShellTab(
        label: l10n.navMarket,
        icon: Icons.show_chart_rounded,
        body: const HomeScreen(),
      ),
      _ShellTab(
        label: l10n.navAlerts,
        icon: Icons.notifications_none_rounded,
        body: const AlertsScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopNavBar(
              tabs: tabs,
              selectedIndex: _index,
              onSelect: (index) => setState(() => _index = index),
            ),
            Expanded(
              // IndexedStack keeps each tab's scroll offset and avoids refetching
              // quotes when the user flips between portfolio and market.
              child: IndexedStack(
                index: _index,
                children: [for (final tab in tabs) tab.body],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fires a notification for every rule whose condition is met, then records
  /// that it fired — which is what stops the next refresh from notifying again.
  Future<void> _dispatchAlerts(Map<String, PriceSnapshot> prices) async {
    // Captured before any await: `context` must not be read afterwards.
    final l10n = context.l10n;
    await _dispatcher.dispatch(
      alerts: ref.read(alertsProvider),
      prices: prices,
      buildCopy: (alert, snapshot) => AlertNotification(
        title: l10n.alertNotificationTitle(alert.symbol),
        body: l10n.alertNotificationBody(
          _conditionText(l10n, alert),
          _priceText(snapshot, alert),
        ),
        channelName: l10n.alertChannelName,
        channelDescription: l10n.alertChannelDescription,
      ),
    );
  }

  String _conditionText(AppLocalizations l10n, Alert alert) {
    final threshold = alert.isPercentKind
        ? '${alert.threshold.toStringAsFixed(2)}%'
        : alert.threshold.toStringAsFixed(2);
    return switch (alert.kind) {
      AlertKind.priceAbove => '${l10n.alertKindPriceAbove} $threshold',
      AlertKind.priceBelow => '${l10n.alertKindPriceBelow} $threshold',
      AlertKind.percentChangeAbove =>
        '${l10n.alertKindPercentAbove} $threshold',
      AlertKind.percentChangeBelow =>
        '${l10n.alertKindPercentBelow} $threshold',
    };
  }

  String _priceText(PriceSnapshot snapshot, Alert alert) => alert.isPercentKind
      ? '${snapshot.dayChangePercent.toStringAsFixed(2)}%'
      : snapshot.price.toStringAsFixed(2);
}

class _ShellTab {
  const _ShellTab({required this.label, required this.icon, required this.body});

  final String label;
  final IconData icon;
  final Widget body;
}

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_ShellTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(kSpace3, kSpace2, kSpace3, 0),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: _NavItem(
                tab: tabs[index],
                selected: index == selectedIndex,
                onTap: () => onSelect(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Semantics(
        selected: selected,
        button: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpace2),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Underline rather than a pill: it reads as a desktop nav rail and
              // keeps the height compact enough for dense tables below.
              Container(
                height: 2.5,
                width: 34,
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
