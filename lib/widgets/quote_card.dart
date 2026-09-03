import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Compact quote card used by the watchlist grid. Mirrors the layout of the
/// original Stocks Widget card: symbol / name on top, price on the left and
/// colored percent/amount change on the right.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onTap,
    this.showMore = true,
    this.onRemove,
    this.roundTwoDp = true,
  });

  final Quote quote;
  final VoidCallback onTap;
  final bool showMore;
  final VoidCallback? onRemove;
  final bool roundTwoDp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = changeColor(
      context,
      quote.isUp
          ? QuoteDirection.up
          : quote.isDown
              ? QuoteDirection.down
              : QuoteDirection.flat,
    );
    final symbol = currencySymbol(quote.currency);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      quote.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (showMore && onRemove != null)
                    _MoreButton(onRemove: onRemove!),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                quote.name.isEmpty ? '—' : quote.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$symbol${priceText(quote.lastPrice, roundTwoDp: roundTwoDp)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        percentText(quote.changePercent),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        signedAmount(quote.change, roundTwoDp: roundTwoDp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: '',
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onSelected: (value) {
          if (value == 'remove') onRemove();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'remove',
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}
