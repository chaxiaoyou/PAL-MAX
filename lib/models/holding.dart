import 'package:isar_community/isar.dart';

part 'holding.g.dart';

/// A portfolio position: how many shares of [symbol] are held and the average
/// cost per share. Nothing market-dependent is persisted — market value and
/// P/L are always derived from the latest quote, so a stale price can never be
/// mistaken for a real one.
@collection
class Holding {
  Id id = Isar.autoIncrement;

  /// Yahoo symbol, e.g. `AAPL`. One position per symbol — [PortfolioNotifier]
  /// is the only writer and it merges by symbol, so an index would only add
  /// generated-code noise here.
  late String symbol;

  late String name;

  /// Number of shares. Fractional shares are allowed.
  late double shares;

  /// Average cost basis per share, in [currency].
  late double costPerShare;

  /// ISO currency code, refreshed from the live quote when one is available.
  late String currency;

  late DateTime createdAt;
  late DateTime updatedAt;
}

/// The editable fields of a position, produced by the editor sheet and applied
/// by the portfolio notifier.
class HoldingDraft {
  const HoldingDraft({
    required this.symbol,
    required this.name,
    required this.shares,
    required this.costPerShare,
    required this.currency,
  });

  final String symbol;
  final String name;
  final double shares;
  final double costPerShare;
  final String currency;
}
