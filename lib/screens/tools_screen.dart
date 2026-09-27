import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tools.dart';
import '../l10n/l10n.dart';
import '../models/tool_definition.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'calc_scaffold.dart';
import 'history_screen.dart';

/// Shown in the pin rail until the user picks their own favourites.
const _starterPins = <String>['risk', 'size', 'compound', 'roi'];

const _categoryIds = <String>[kCategoryTrading, kCategoryInvestment];

/// Calculator catalogue.
///
/// Composition: an app bar with search and saved-results actions, a rail of
/// pinned calculators (favourites, or a starter set), then the remaining tools
/// grouped by category as compact rows. Searching collapses everything into a
/// flat result list.
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  final TextEditingController _queryCtrl = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  String get _query => _queryCtrl.text.trim().toLowerCase();

  List<ToolDefinition> get _results {
    final l10n = context.l10n;
    return appTools
        .where((tool) =>
            toolTitle(l10n, tool.id).toLowerCase().contains(_query) ||
            toolSubtitle(l10n, tool.id).toLowerCase().contains(_query) ||
            categoryTitle(l10n, tool.categoryId).toLowerCase().contains(_query))
        .toList();
  }

  void _openTool(ToolDefinition tool) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => buildCalculatorScreen(tool)),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) _queryCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favorites = ref.watch(favoritesProvider);
    final searching = _searchOpen || _query.isNotEmpty;

    final pinned = favorites.isEmpty
        ? appTools.where((tool) => _starterPins.contains(tool.id)).toList()
        : appTools.where((tool) => favorites.contains(tool.id)).toList();
    final pinnedIds = pinned.map((tool) => tool.id).toSet();
    final grouped = {
      for (final categoryId in _categoryIds)
        categoryId: appTools
            .where((tool) =>
                tool.categoryId == categoryId && !pinnedIds.contains(tool.id))
            .toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.toolsTitle),
        actions: [
          IconButton(
            tooltip: l10n.tooltipSearchCalculators,
            onPressed: _toggleSearch,
            icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded),
          ),
          IconButton(
            tooltip: l10n.tooltipSavedResults,
            onPressed: _openHistory,
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (_searchOpen)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _queryCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.searchHintCalculators,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.actionClear,
                            onPressed: () {
                              _queryCtrl.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
          if (searching)
            ..._buildResultsSlivers(context, favorites)
          else ...[
            SliverToBoxAdapter(
              child: _SummaryBanner(
                total: appTools.length,
                pinned: pinned.length,
                favorites: favorites.length,
              ),
            ),
            if (pinned.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: favorites.isEmpty
                      ? l10n.sectionStartHere
                      : l10n.sectionPinned,
                  hint: favorites.isEmpty
                      ? l10n.hintStarToPin
                      : l10n.hintTapToUnpin,
                ),
              ),
              SliverToBoxAdapter(
                child: _PinRail(
                  tools: pinned,
                  onTap: _openTool,
                  onToggle: (tool) =>
                      ref.read(favoritesProvider.notifier).toggle(tool.id),
                ),
              ),
            ],
            for (final categoryId in _categoryIds) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: categoryTitle(l10n, categoryId),
                  hint: categoryHint(l10n, categoryId),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                sliver: SliverList.separated(
                  itemCount: grouped[categoryId]!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tool = grouped[categoryId]![index];
                    return _ToolRow(
                      tool: tool,
                      pinned: favorites.contains(tool.id),
                      onTap: () => _openTool(tool),
                      onTogglePin: () =>
                          ref.read(favoritesProvider.notifier).toggle(tool.id),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: DisclaimerFooter()),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildResultsSlivers(
    BuildContext context,
    Set<String> favorites,
  ) {
    final theme = Theme.of(context);
    final results = _results;
    if (results.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 44,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n
                        .noCalculatorMatches(_queryCtrl.text.trim()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: context.l10n.sectionResults,
          hint: context.l10n.resultsShownOfTotal(results.length, appTools.length),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        sliver: SliverList.separated(
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tool = results[index];
            return _ToolRow(
              tool: tool,
              pinned: favorites.contains(tool.id),
              onTap: () => _openTool(tool),
              onTogglePin: () =>
                  ref.read(favoritesProvider.notifier).toggle(tool.id),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: DisclaimerFooter()),
    ];
  }
}

/// Brand-tinted summary card: how many tools exist, how many are pinned and
/// the reassurance that the math never leaves the device.
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.pinned,
    required this.favorites,
  });

  final int total;
  final int pinned;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGutter, kSpace1, kGutter, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kSpace4),
        decoration: BoxDecoration(
          // Flat brand wash: same emphasis as the old gradient without the
          // muddy two-stop blend against the canvas.
          color: Color.alphaBlend(
            theme.colorScheme.primary.withValues(alpha: 0.07),
            theme.colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.functions_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: kSpace3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.summaryCalculators(total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    favorites == 0
                        ? l10n.summaryStarterPicks(pinned)
                        : l10n.summaryPinned(favorites),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinRail extends StatelessWidget {
  const _PinRail({
    required this.tools,
    required this.onTap,
    required this.onToggle,
  });

  final List<ToolDefinition> tools;
  final ValueChanged<ToolDefinition> onTap;
  final ValueChanged<ToolDefinition> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        itemCount: tools.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _PinTile(
            tool: tool,
            onTap: () => onTap(tool),
            onToggle: () => onToggle(tool),
          );
        },
      ),
    );
  }
}

class _PinTile extends StatelessWidget {
  const _PinTile({
    required this.tool,
    required this.onTap,
    required this.onToggle,
  });

  final ToolDefinition tool;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 112,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: tool.color.withValues(alpha: 0.28)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: tool.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tool.icon, color: tool.color, size: 17),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: tool.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  toolTitle(context.l10n, tool.id),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.tool,
    required this.pinned,
    required this.onTap,
    required this.onTogglePin,
  });

  final ToolDefinition tool;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(tool.icon, color: tool.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toolTitle(context.l10n, tool.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      toolSubtitle(context.l10n, tool.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: pinned ? context.l10n.actionUnpin : context.l10n.actionPin,
                visualDensity: VisualDensity.compact,
                onPressed: onTogglePin,
                icon: Icon(
                  pinned ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                  color: pinned
                      ? tool.color
                      : theme.colorScheme.outline,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
