import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tools.dart';
import '../models/tool_definition.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'calc_scaffold.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _tabs = ['All', 'Investment', 'Trading'];
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final filtered = appTools.where((tool) {
      final categoryMatch = _tab == 0 ||
          (_tab == 1 ? tool.category == 'Investment' : tool.category == 'Trading');
      return categoryMatch &&
          (_query.isEmpty || tool.title.contains(_query.trim()));
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PAL MAX',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            'Invest & trade,\nwith confidence.',
                            style: TextStyle(
                              fontSize: 29,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ink.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            tooltip: 'Profile',
                            icon: const Icon(Icons.person_rounded,
                                color: ink, size: 23),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ),
                            tooltip: 'Saved records',
                            icon: const Icon(Icons.history_rounded,
                                color: ink, size: 23),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: muted),
                    hintText: 'Search calculators',
                    hintStyle: const TextStyle(color: muted),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: ChoiceChip(
                          label: Text(_tabs[i]),
                          selected: _tab == i,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _tab = i),
                          selectedColor: ink,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _tab == i ? Colors.white : muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          side: BorderSide.none,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'No matching tools',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tool = filtered[index];
                      return ToolCard(
                        tool: tool,
                        favorite: favorites.contains(tool.id),
                        onFavorite: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(tool.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                buildCalculatorScreen(tool),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: 0.92,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: DisclaimerFooter()),
          ],
        ),
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final ToolDefinition tool;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: tool.color.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: tool.color, size: 22),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onFavorite,
                  icon: Icon(
                    favorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 21,
                    color: favorite ? const Color(0xffffb020) : muted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              tool.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tool.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.35, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
