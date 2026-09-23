/// A single cash dividend, per share.
///
/// Yahoo reports these as a timestamped amount per share under
/// `chart.result[].events.dividends`, which is the same endpoint the price
/// history uses — no extra vendor, and no forward-looking claim: this is money
/// that has already been paid.
class DividendPayment {
  const DividendPayment({
    required this.symbol,
    required this.amount,
    required this.date,
  });

  final String symbol;

  /// Cash per share, in the instrument's own currency.
  final double amount;

  /// Ex-dividend date, in UTC.
  final DateTime date;
}
