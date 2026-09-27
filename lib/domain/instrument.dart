/// Domain entities for the portfolio-centric app.
///
/// These are deliberately separate from the quote models in `lib/models`: a
/// quote is a point-in-time market snapshot, while an instrument is a thing the
/// user can hold, and therefore outlives any single fetch.
library;

// `index` would collide with the enum's own positional index.
enum InstrumentType { stock, etf, marketIndex, fund, crypto, other }

class Instrument {
  const Instrument({
    required this.symbol,
    this.name = '',
    this.type = InstrumentType.stock,
    this.currency = 'MXN',
    this.exchange = '',
  });

  final String symbol;
  final String name;
  final InstrumentType type;

  /// ISO code the instrument is quoted in. Mexican listings default to MXN so
  /// a mixed USD/MXN portfolio is explicit rather than accidental.
  final String currency;
  final String exchange;

  Instrument copyWith({
    String? name,
    InstrumentType? type,
    String? currency,
    String? exchange,
  }) {
    return Instrument(
      symbol: symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      exchange: exchange ?? this.exchange,
    );
  }

  @override
  String toString() => 'Instrument($symbol, $currency)';
}
