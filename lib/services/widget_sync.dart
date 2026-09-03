import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/quote.dart';
import '../utils/format.dart';

/// Bridges the watchlist snapshot to the native Android home-screen widget.
/// The widget itself stays offline: it renders whatever the app last fetched.
class WidgetSync {
  static const _channel = MethodChannel('pal_max/stocks_widget');

  static Future<void> saveSnapshot({
    required List<String> symbols,
    required List<Quote> quotes,
    required bool dark,
    bool roundTwoDp = true,
    DateTime? updatedAt,
  }) async {
    if (!Platform.isAndroid) return;
    final payload = jsonEncode({
      'dark': dark,
      'updatedAt': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'symbols': symbols,
      'quotes': [
        for (final quote in quotes)
          {
            'symbol': quote.symbol,
            'name': quote.name,
            'lastPrice': quote.lastPrice,
            'change': quote.change,
            'changePercent': quote.changePercent,
            'priceText':
                '${currencySymbol(quote.currency)}${priceText(quote.lastPrice, roundTwoDp: roundTwoDp)}',
            'percentText': percentText(quote.changePercent),
            'changeText': signedAmount(quote.change, roundTwoDp: roundTwoDp),
          },
      ],
    });
    try {
      await _channel.invokeMethod<void>('update', payload);
    } catch (error, stackTrace) {
      debugPrint('widget snapshot failed: $error\n$stackTrace');
    }
  }
}
