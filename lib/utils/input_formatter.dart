import 'package:flutter/services.dart';

/// Allows digits and a single decimal point (max 2 decimals) and
/// automatically adds thousands separators to the integer part.
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({
    this.maxIntDigits = 15,
    this.maxDecimals = 2,
  });

  final int maxIntDigits;
  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return const TextEditingValue();
    if (text == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    final buffer = StringBuffer();
    var dotSeen = false;
    var decimals = 0;
    var intDigits = 0;
    for (final ch in text.split('')) {
      if (ch == '.') {
        if (!dotSeen) {
          dotSeen = true;
          buffer.write(ch);
        }
      } else if (_isDigit(ch)) {
        if (dotSeen) {
          if (decimals >= maxDecimals) continue;
          decimals++;
        } else {
          if (intDigits >= maxIntDigits) continue;
          intDigits++;
        }
        buffer.write(ch);
      }
    }
    final raw = buffer.toString();

    final String formatted;
    final dotIndex = raw.indexOf('.');
    if (dotIndex == -1) {
      formatted = _group(raw);
    } else {
      formatted = '${_group(raw.substring(0, dotIndex))}.${raw.substring(dotIndex + 1)}';
    }

    final sel = newValue.selection;
    final rawPos = (sel.isValid ? sel.end : text.length).clamp(0, text.length);
    var digitsBefore = 0;
    for (var i = 0; i < rawPos; i++) {
      if (_isDigit(text[i])) digitsBefore++;
    }

    var newPos = 0;
    var seen = 0;
    while (newPos < formatted.length && seen < digitsBefore) {
      if (_isDigit(formatted[newPos])) seen++;
      newPos++;
    }
    if (rawPos >= raw.length && raw.contains('.')) {
      final fDot = formatted.indexOf('.');
      if (fDot >= 0) newPos = fDot + 1;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newPos),
    );
  }

  bool _isDigit(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  String _group(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write(',');
    }
    return buffer.toString().split('').reversed.join();
  }
}
