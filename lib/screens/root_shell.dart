import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'tools_screen.dart';

/// Bottom-navigation shell: live watchlist, the calculator tools and the
/// saved results. Keeping the three in one `IndexedStack` preserves scroll
/// positions and avoids refetching quotes when switching tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          ToolsScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.show_chart_rounded),
            selectedIcon: const Icon(Icons.show_chart_rounded),
            label: l10n.navWatchlist,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calculate_outlined),
            selectedIcon: const Icon(Icons.calculate_rounded),
            label: l10n.navCalculators,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border_rounded),
            selectedIcon: const Icon(Icons.bookmark_rounded),
            label: l10n.navSaved,
          ),
        ],
      ),
    );
  }
}
