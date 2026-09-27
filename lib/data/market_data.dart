import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/providers.dart';
import '../services/yahoo_service.dart';

/// Provider-agnostic market data contract.
///
/// Everything above this line (portfolio valuation, alerts, screens) only knows
/// this interface, so swapping the public Yahoo endpoints for a commercial API
/// — Finnhub, Twelve Data, or BMV's own feed — is a one-class change with no
/// ripple through the app. That matters because the endpoints currently used
/// are unofficial and can change or start rejecting traffic without notice.
abstract class MarketDataProvider {
  /// Latest quotes for [symbols]. Symbols that cannot be priced are simply
  /// absent from the result; callers must treat missing as missing rather than
  /// as zero.
  Future<List<Quote>> quotes(List<String> symbols);

  /// Conversion rate from [from] into [to], or null when unavailable. Returns 1
  /// for identical currencies without a request.
  Future<double?> fxRate(String from, String to);
}

/// Current implementation: the existing Yahoo Finance client, wrapped so the
/// rest of the app stops depending on it directly.
class YahooMarketData implements MarketDataProvider {
  YahooMarketData(this._api);

  final YahooFinanceApi _api;

  @override
  Future<List<Quote>> quotes(List<String> symbols) => _api.fetchQuotes(symbols);

  @override
  Future<double?> fxRate(String from, String to) async {
    if (from == to) return 1;
    final quotes = await _api.fetchQuotes(['$from$to=X']);
    if (quotes.isEmpty) return null;
    final rate = quotes.first.lastPrice;
    if (!rate.isFinite || rate <= 0) return null;
    return rate;
  }
}

final marketDataProvider = Provider<MarketDataProvider>(
  (ref) => YahooMarketData(ref.watch(yahooApiProvider)),
);
