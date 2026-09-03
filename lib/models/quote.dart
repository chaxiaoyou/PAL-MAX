/// Domain models mirroring the pieces of the Yahoo Finance responses used by
/// the open-source Stocks Widget app.
library;

class Quote {
  const Quote({
    required this.symbol,
    required this.name,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    this.currency = 'USD',
    this.exchange = '',
    this.quoteType = '',
    this.marketState = '',
    this.open,
    this.dayHigh,
    this.dayLow,
    this.previousClose = 0,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.fiftyDayAverage,
    this.twoHundredDayAverage,
    this.trailingPE,
    this.volume,
    this.marketCap,
  });

  final String symbol;
  final String name;
  final double lastPrice;
  final double change;
  final double changePercent;
  final String currency;
  final String exchange;
  final String quoteType;
  final String marketState;
  final double? open;
  final double? dayHigh;
  final double? dayLow;
  final double previousClose;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final double? fiftyDayAverage;
  final double? twoHundredDayAverage;
  final double? trailingPE;
  final num? volume;
  final num? marketCap;

  bool get isUp => change > 0;
  bool get isDown => change < 0;
  bool get isIndex => quoteType == 'INDEX' || symbol.startsWith('^');

  factory Quote.fromYahooJson(Map<String, dynamic> json) {
    double readNum(String key) =>
        (json[key] is num) ? (json[key] as num).toDouble() : 0.0;
    double? readOpt(String key) =>
        (json[key] is num) ? (json[key] as num).toDouble() : null;
    num? readNumOpt(String key) => json[key] is num ? json[key] as num : null;

    final shortName = json['shortName'] ?? json['longName'];
    return Quote(
      symbol: (json['symbol'] as String?) ?? '',
      name: (shortName as String?) ?? '',
      lastPrice: readNum('regularMarketPrice'),
      change: readNum('regularMarketChange'),
      changePercent: readNum('regularMarketChangePercent'),
      currency: (json['currency'] as String?) ?? 'USD',
      exchange: (json['exchange'] as String?) ?? '',
      quoteType: (json['quoteType'] as String?) ?? '',
      marketState: (json['marketState'] as String?) ?? '',
      open: readOpt('regularMarketOpen'),
      dayHigh: readOpt('regularMarketDayHigh'),
      dayLow: readOpt('regularMarketDayLow'),
      previousClose: readNum('regularMarketPreviousClose'),
      fiftyTwoWeekHigh: readOpt('fiftyTwoWeekHigh'),
      fiftyTwoWeekLow: readOpt('fiftyTwoWeekLow'),
      fiftyDayAverage: readOpt('fiftyDayAverage'),
      twoHundredDayAverage: readOpt('twoHundredDayAverage'),
      trailingPE: readOpt('trailingPE'),
      volume: readNumOpt('regularMarketVolume'),
      marketCap: readNumOpt('marketCap'),
    );
  }
}

class ChartPoint {
  const ChartPoint({required this.time, required this.close});

  final int time;
  final double close;
}

class SearchResult {
  const SearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
  });

  final String symbol;
  final String name;
  final String exchange;
  final String type;

  factory SearchResult.fromYahooJson(Map<String, dynamic> json) {
    final shortName = json['shortname'] ?? json['longname'];
    return SearchResult(
      symbol: (json['symbol'] as String?) ?? '',
      name: (shortName as String?) ?? '',
      exchange: (json['exchDisp'] as String?) ?? '',
      type: (json['typeDisp'] as String?) ?? '',
    );
  }
}

class NewsItem {
  const NewsItem({
    required this.title,
    required this.link,
    required this.description,
    required this.pubDate,
  });

  final String title;
  final String link;
  final String description;
  final DateTime pubDate;
}
