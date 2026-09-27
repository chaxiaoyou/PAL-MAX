import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

const _refreshChoices = <int>[2, 5, 15, 30, 60];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPrefsProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _sectionTitle(context, l10n.sectionAppearance),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.settingTheme),
                  subtitle: Text(_themeLabel(context, prefs.theme)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickTheme(context, ref),
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.settingLanguage),
                  subtitle: Text(_languageLabel(context, prefs.language)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickLanguage(context, ref),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.settingAutoSort),
                  subtitle: Text(l10n.settingAutoSortSub),
                  value: prefs.autoSort,
                  onChanged: (value) =>
                      ref.read(appPrefsProvider.notifier).setAutoSort(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, l10n.sectionQuotes),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.settingRefreshInterval),
                  subtitle: Text(l10n.minutesCount(prefs.refreshMinutes)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickInterval(context, ref),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.settingRoundPrices),
                  value: prefs.roundTwoDp,
                  onChanged: (value) =>
                      ref.read(appPrefsProvider.notifier).setRoundTwoDp(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, l10n.sectionAbout),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(l10n.aboutDataSource),
                  subtitle: Text(l10n.aboutDataSourceSub),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(l10n.aboutCalculators),
                  subtitle: Text(l10n.aboutCalculatorsSub),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.aboutDisclaimer),
                  subtitle: Text(l10n.aboutDisclaimerSub),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              kAppName,
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

  String _themeLabel(BuildContext context, ThemePreference preference) =>
      switch (preference) {
        ThemePreference.system => context.l10n.themeSystem,
        ThemePreference.light => context.l10n.themeLight,
        ThemePreference.dark => context.l10n.themeDark,
      };

  String _languageLabel(BuildContext context, AppLanguage language) =>
      switch (language) {
        AppLanguage.system => context.l10n.languageSystem,
        AppLanguage.english => context.l10n.languageEnglish,
        AppLanguage.spanish => context.l10n.languageSpanish,
        AppLanguage.japanese => context.l10n.languageJapanese,
      };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(appPrefsProvider).theme;
    final selected = await showDialog<ThemePreference>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingTheme),
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
                    title: Text(_themeLabel(dialogContext, preference)),
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

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(appPrefsProvider).language;
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingLanguage),
        children: [
          RadioGroup<AppLanguage>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) Navigator.pop(dialogContext, value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    title: Text(_languageLabel(dialogContext, language)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(appPrefsProvider.notifier).setLanguage(selected);
    }
  }

  Future<void> _pickInterval(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(appPrefsProvider).refreshMinutes;
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingRefreshInterval),
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
                    title: Text(l10n.minutesCount(minutes)),
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

}
