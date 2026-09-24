import 'package:intl/intl.dart';

final NumberFormat _money2 = NumberFormat('#,##0.00');
final NumberFormat _moneyAuto = NumberFormat('#,##0.##');
final NumberFormat _pct2 = NumberFormat('0.00');

// Calculator formatters (amounts keep two decimals, plain numbers trim zeros).
final NumberFormat _amountFmt = NumberFormat('#,##0.00');
final NumberFormat _numFmt = NumberFormat('#,##0.##');

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

/// Calculator amount, always two decimals, e.g. `1,234.50`.
String fmtAmount(double v) => v.isFinite ? _amountFmt.format(v) : '--';

/// Calculator number with trailing zeros trimmed, e.g. `1,234.5`.
String fmtNum(double v) => v.isFinite ? _numFmt.format(v) : '--';

/// Calculator percentage, e.g. `12.5%`.
String fmtPct(double v) => v.isFinite ? '${_numFmt.format(v)}%' : '--';

/// Signed number without a leading `+`, e.g. `12.5` / `-3`.
String fmtSigned(double v) {
  if (!v.isFinite) return '--';
  final abs = _numFmt.format(v.abs());
  return v < 0 ? '-$abs' : abs;
}

/// Used to prefill inputs: whole numbers without decimals, otherwise max 2
/// decimals.
String fmtInput(double v) {
  if (!v.isFinite) return '';
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

/// Parses a (possibly thousands-separated) user input into a number.
double parseNum(String text) =>
    double.tryParse(text.replaceAll(',', '').trim()) ?? 0;

String two(int n) => n.toString().padLeft(2, '0');

String hhMm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

String fmtDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';

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
