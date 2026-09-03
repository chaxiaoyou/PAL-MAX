import 'package:intl/intl.dart';

final NumberFormat _money2 = NumberFormat('#,##0.00');
final NumberFormat _moneyAuto = NumberFormat('#,##0.##');
final NumberFormat _pct2 = NumberFormat('0.00');

/// Formats a price/amount. With [roundTwoDp] the value is always shown with two
/// decimals (e.g. `1,234.50`), otherwise trailing zeros are trimmed.
String priceText(double v, {bool roundTwoDp = true}) {
  if (!v.isFinite) return '--';
  return roundTwoDp ? _money2.format(v) : _moneyAuto.format(v);
}

/// Signed amount, e.g. `+12.34` / `-5.60`.
String signedAmount(double v, {bool roundTwoDp = true}) {
  if (!v.isFinite) return '--';
  final text = priceText(v.abs(), roundTwoDp: roundTwoDp);
  if (v > 0) return '+$text';
  if (v < 0) return '-$text';
  return text;
}

/// Percent change, e.g. `+0.16%`.
String percentText(double v, {bool signed = true}) {
  if (!v.isFinite) return '--';
  final text = '${_pct2.format(v.abs())}%';
  if (!signed) return text;
  if (v > 0) return '+$text';
  if (v < 0) return '-$text';
  return text;
}

/// Compact big-number format used for volume / market cap (12.34B etc.).
String compactNumber(num v) {
  if (!v.isFinite) return '--';
  final abs = v.abs();
  if (abs >= 1e12) return '${_trim(abs / 1e12)}T';
  if (abs >= 1e9) return '${_trim(abs / 1e9)}B';
  if (abs >= 1e6) return '${_trim(abs / 1e6)}M';
  if (abs >= 1e3) return '${_trim(abs / 1e3)}K';
  return v.toStringAsFixed(0);
}

String _trim(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('0')
      ? value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')
      : fixed;
}

String two(int n) => n.toString().padLeft(2, '0');

String hhMm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// Currency symbol used by the original app for common currencies.
String currencySymbol(String code) {
  const map = <String, String>{
    'USD': r'$',
    'CAD': r'$',
    'AUD': r'$',
    'ARS': r'$',
    'BRL': r'R$',
    'CHF': 'CHF',
    'CNY': 'CN¥',
    'EUR': '€',
    'GBP': '£',
    'HKD': r'$',
    'INR': '₹',
    'JPY': '¥',
    'KRW': '₩',
    'MXN': r'$',
    'SGD': r'$',
    'TWD': r'NT$',
  };
  return map[code] ?? code;
}
