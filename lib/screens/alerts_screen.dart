import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/portfolio_store.dart';
import '../domain/alert.dart';
import '../domain/position.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Price alert rules, evaluated against the same snapshots the portfolio uses.
///
/// Rules are listed with how far the market still is from the threshold, which
/// is the question a user actually has; "armed" alone tells them nothing.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final alerts = ref.watch(alertsProvider);
    final prices = ref.watch(portfolioPricesProvider);
    final snapshots = prices.valueOrNull ?? const <String, PriceSnapshot>{};

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createAlert(context, ref),
        icon: const Icon(Icons.add_alert_rounded),
        label: Text(l10n.alertAdd),
      ),
      body: alerts.isEmpty
          ? _EmptyAlerts(onAdd: () => _createAlert(context, ref))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                kGutter,
                kSpace3,
                kGutter,
                kSpace6 * 2,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.alertsTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpace3),
                for (final alert in alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: kSpace3),
                    child: _AlertCard(
                      alert: alert,
                      evaluation: evaluateAlert(
                        alert,
                        price: snapshots[alert.symbol]?.price ?? double.nan,
                        changePercent: _changePercent(snapshots[alert.symbol]),
                      ),
                      hasPrice: snapshots.containsKey(alert.symbol),
                    ),
                  ),
              ],
            ),
    );
  }

  static double? _changePercent(PriceSnapshot? snapshot) {
    if (snapshot == null || !snapshot.hasPreviousClose) return null;
    return snapshot.dayChangePercent;
  }
}

Future<void> _createAlert(BuildContext context, WidgetRef ref) async {
  final draft = await showModalBottomSheet<_AlertDraft>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _AlertSheet(),
  );
  if (draft == null) return;
  await ref.read(alertsProvider.notifier).add(
        Alert(
          id: 'alert-${DateTime.now().microsecondsSinceEpoch}',
          symbol: draft.symbol,
          kind: draft.kind,
          threshold: draft.threshold,
          createdAt: DateTime.now(),
        ),
      );
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({
    required this.alert,
    required this.evaluation,
    required this.hasPrice,
  });

  final Alert alert;
  final AlertEvaluation evaluation;
  final bool hasPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final notifier = ref.read(alertsProvider.notifier);
    final (statusText, statusColor) = _status(context);

    return Container(
      padding: const EdgeInsets.all(kSpace3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(
          color: alert.isTriggered
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.symbol,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: alert.enabled,
                onChanged: (_) => notifier.toggleEnabled(alert),
              ),
              IconButton(
                tooltip: l10n.actionDelete,
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
          Text(
            '${_kindLabel(context, alert.kind)} '
            '${_thresholdText(alert)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                statusText,
                style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
              ),
              // Only while there is still ground to cover: once the threshold
              // is crossed the status line already says so, and printing it
              // twice reads like a rendering bug.
              if (evaluation.distance != null && evaluation.distance! > 0) ...[
                const SizedBox(width: kSpace2),
                Text(
                  _distanceText(context, evaluation.distance!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (alert.isTriggered) ...[
            const SizedBox(height: kSpace2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => notifier.reArm(alert),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(l10n.alertReArm),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _status(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (alert.isTriggered) {
      return (
        l10n.alertStatusTriggered(fmtDateTime(alert.triggeredAt!)),
        theme.colorScheme.primary,
      );
    }
    if (!alert.enabled) {
      return (l10n.alertStatusPaused, theme.colorScheme.onSurfaceVariant);
    }
    // The condition is met right now. Notifications are not wired yet, so the
    // card says so instead of silently looking armed.
    if (evaluation.triggered) {
      return (l10n.alertDistanceCrossed, theme.colorScheme.primary);
    }
    if (!hasPrice) {
      return (l10n.alertNoPrice, theme.colorScheme.onSurfaceVariant);
    }
    return (l10n.alertStatusArmed, theme.colorScheme.onSurfaceVariant);
  }

  String _distanceText(BuildContext context, double distance) {
    final l10n = context.l10n;
    if (distance <= 0) return l10n.alertDistanceCrossed;
    return l10n.alertDistanceAhead(
      alert.isPercentKind ? fmtPct(distance) : fmtNum(distance),
    );
  }

  String _thresholdText(Alert alert) =>
      alert.isPercentKind ? fmtPct(alert.threshold) : fmtNum(alert.threshold);

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.alertDeleteTitle),
        content: Text(l10n.alertDeleteMessage(alert.symbol)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(alertsProvider.notifier).remove(alert.id);
    }
  }
}

String _kindLabel(BuildContext context, AlertKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    AlertKind.priceAbove => l10n.alertKindPriceAbove,
    AlertKind.priceBelow => l10n.alertKindPriceBelow,
    AlertKind.percentChangeAbove => l10n.alertKindPercentAbove,
    AlertKind.percentChangeBelow => l10n.alertKindPercentBelow,
  };
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.onAdd});

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
              Icons.notifications_none_rounded,
              size: 52,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: kSpace3),
            Text(
              l10n.alertsEmptyTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.alertsEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: kSpace4),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alert_rounded),
              label: Text(l10n.alertAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertDraft {
  const _AlertDraft({
    required this.symbol,
    required this.kind,
    required this.threshold,
  });

  final String symbol;
  final AlertKind kind;
  final double threshold;
}

class _AlertSheet extends StatefulWidget {
  const _AlertSheet();

  @override
  State<_AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<_AlertSheet> {
  final _symbolCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  AlertKind _kind = AlertKind.priceAbove;
  String? _error;

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
            l10n.alertAdd,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: kSpace3),
          TextField(
            controller: _symbolCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.alertSymbol),
          ),
          const SizedBox(height: kSpace3),
          DropdownButtonFormField<AlertKind>(
            initialValue: _kind,
            decoration: InputDecoration(labelText: l10n.alertsTitle),
            items: [
              for (final kind in AlertKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text(_kindLabel(context, kind)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _kind = value);
            },
          ),
          const SizedBox(height: kSpace3),
          TextField(
            controller: _thresholdCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: l10n.alertThreshold,
              errorText: _error,
            ),
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

  void _submit() {
    final l10n = context.l10n;
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() => _error = l10n.alertNeedSymbol);
      return;
    }
    final raw = _thresholdCtrl.text.trim().replaceAll(',', '');
    final threshold = double.tryParse(raw);
    if (threshold == null || !threshold.isFinite) {
      setState(() => _error = l10n.alertNeedThreshold);
      return;
    }
    Navigator.pop(
      context,
      _AlertDraft(symbol: symbol, kind: _kind, threshold: threshold),
    );
  }
}
