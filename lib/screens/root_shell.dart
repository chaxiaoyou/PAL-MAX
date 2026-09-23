import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'home_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';

/// Bottom-tab shell: watchlist, portfolio, settings.
///
/// [IndexedStack] keeps every tab alive while switching, so the watchlist
/// refresh timer and the desktop-widget snapshot keep working no matter which
/// tab is on screen.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Held alive here rather than from the alerts screen: price alerts have to
    // keep being evaluated while the app is open, whether or not the user is
    // looking at the tab that lists them.
    ref.watch(alertsProvider);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PortfolioScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
