import 'package:intl/intl.dart';

final NumberFormat _amountFmt = NumberFormat('#,##0.00');
final NumberFormat _numFmt = NumberFormat('#,##0.##');

String fmtAmount(double v) => v.isFinite ? _amountFmt.format(v) : '--';

String fmtNum(double v) => v.isFinite ? _numFmt.format(v) : '--';

String fmtPct(double v) => v.isFinite ? '${_numFmt.format(v)}%' : '--';

String fmtSigned(double v) {
  if (!v.isFinite) return '--';
  final abs = _numFmt.format(v.abs());
  return v < 0 ? '-$abs' : abs;
}

/// Used to prefill inputs: whole numbers without decimals, otherwise max 2 decimals.
String fmtInput(double v) {
  if (!v.isFinite) return '';
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

double parseNum(String text) =>
    double.tryParse(text.replaceAll(',', '').trim()) ?? 0;

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';
