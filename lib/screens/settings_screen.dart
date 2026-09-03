import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'webview_screen.dart';

const _refreshChoices = <int>[2, 5, 15, 30, 60];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPrefsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _sectionTitle(context, 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Theme'),
                  subtitle: Text(_themeLabel(prefs.theme)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickTheme(context, ref),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Auto-sort by daily change'),
                  subtitle: const Text('Sort watchlist by today’s percent change'),
                  value: prefs.autoSort,
                  onChanged: (value) =>
                      ref.read(appPrefsProvider.notifier).setAutoSort(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Quotes'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Refresh interval'),
                  subtitle: Text('${prefs.refreshMinutes} minutes'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickInterval(context, ref),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Round prices to 2 decimals'),
                  value: prefs.roundTwoDp,
                  onChanged: (value) =>
                      ref.read(appPrefsProvider.notifier).setRoundTwoDp(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Open-source project'),
                  subtitle: const Text('github.com/premnirmal/stockticker'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl(
                    context,
                    'https://github.com/premnirmal/stockticker',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Data source'),
                  subtitle: const Text('Quotes & charts by Yahoo Finance'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '$kAppName · Flutter replica',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _themeLabel(ThemePreference preference) => switch (preference) {
        ThemePreference.system => 'Follow system',
        ThemePreference.light => 'Light',
        ThemePreference.dark => 'Dark',
      };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appPrefsProvider).theme;
    final selected = await showDialog<ThemePreference>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemePreference>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) Navigator.pop(dialogContext, value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final preference in ThemePreference.values)
                  RadioListTile<ThemePreference>(
                    value: preference,
                    title: Text(_themeLabel(preference)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(appPrefsProvider.notifier).setTheme(selected);
    }
  }

  Future<void> _pickInterval(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appPrefsProvider).refreshMinutes;
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Refresh interval'),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) Navigator.pop(dialogContext, value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final minutes in _refreshChoices)
                  RadioListTile<int>(
                    value: minutes,
                    title: Text('$minutes minutes'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(appPrefsProvider.notifier).setRefreshMinutes(selected);
    }
  }

  void _openUrl(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WebViewScreen(url: url)),
    );
  }
}
