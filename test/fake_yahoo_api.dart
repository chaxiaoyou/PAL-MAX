import 'package:pjza/models/quote.dart';
import 'package:pjza/services/yahoo_service.dart';

/// Offline stand-in for [YahooFinanceApi]: returns canned quotes so widget
/// tests never touch the network.
class FakeYahooApi extends YahooFinanceApi {
  FakeYahooApi(this.quotes);

  final List<Quote> quotes;

  int fetchCount = 0;
  List<String> lastRequested = const [];

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    fetchCount++;
    lastRequested = List.of(symbols);
    return quotes.where((q) => symbols.contains(q.symbol)).toList();
  }

  @override
  Future<List<Quote>> fetchQuote(String symbol) async =>
      quotes.where((q) => q.symbol == symbol).toList();

  @override
  Future<List<ChartPoint>> fetchChart(
    String symbol, {
    required String range,
    required String interval,
  }) async =>
      const [];

  @override
  Future<List<SearchResult>> search(String query) async => const [];

  @override
  Future<List<NewsItem>> fetchNews(String symbol) async => const [];

  @override
  void dispose() {}
}

Quote fakeQuote({
  required String symbol,
  required String name,
  required double price,
  required double changePercent,
  String quoteType = 'EQUITY',
  String marketState = 'REGULAR',
}) {
  return Quote(
    symbol: symbol,
    name: name,
    lastPrice: price,
    change: price * changePercent / 100,
    changePercent: changePercent,
    quoteType: quoteType,
    marketState: marketState,
    previousClose: price - price * changePercent / 100,
  );
}
