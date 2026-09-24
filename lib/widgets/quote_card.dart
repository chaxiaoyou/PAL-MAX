import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Compact quote card used by the watchlist grid. Mirrors the layout of the
/// original Needham Capital card: symbol / name on top, price on the left and
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
    final showMenu = showMore && onRemove != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // The menu sits on top of the card rather than in its first row: a
        // tap target worth having is taller than the symbol line, and letting
        // it set the row's height squeezes the numbers on a narrow grid.
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                showMenu ? 44 : Space.md,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    quote.name.isEmpty ? '—' : quote.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
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
                            style: theme.textTheme.titleMedium,
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
            if (showMenu)
              Positioned(
                top: 0,
                right: 0,
                child: _MoreButton(onRemove: onRemove!),
              ),
          ],
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
    // The mark stays small; the target around it keeps the 48dp a thumb needs.
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: '',
        iconSize: 20,
        icon: Icon(
          Icons.more_vert_rounded,
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
