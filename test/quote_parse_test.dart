import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pal_max/models/quote.dart';
import 'package:pal_max/utils/format.dart';

void main() {
  group('Quote.fromYahooJson', () {
    test('maps v7 quote payload', () {
      final raw = jsonDecode('''
      {
        "quoteResponse": {
          "result": [
            {
              "symbol": "AAPL",
              "shortName": "Apple Inc.",
              "regularMarketPrice": 275.93,
              "regularMarketChange": 0.78,
              "regularMarketChangePercent": 0.28,
              "currency": "USD",
              "exchange": "NMS",
              "quoteType": "EQUITY",
              "marketState": "REGULAR",
              "regularMarketOpen": 274.1,
              "regularMarketDayHigh": 277.2,
              "regularMarketDayLow": 273.4,
              "regularMarketPreviousClose": 275.15,
              "regularMarketVolume": 51234567,
              "marketCap": 4200000000000,
              "trailingPE": 35.1
            },
            {
              "symbol": "^GSPC",
              "shortName": "S&P 500",
              "regularMarketPrice": 7369.6,
              "regularMarketChange": 11.8,
              "regularMarketChangePercent": 0.16,
              "currency": "USD",
              "quoteType": "INDEX",
              "marketState": "CLOSED"
            }
          ]
        }
      }
      ''');
      final map = raw as Map<String, dynamic>;
      final results =
          (map['quoteResponse']['result'] as List).cast<Map<String, dynamic>>();
      final quotes = results.map(Quote.fromYahooJson).toList();

      expect(quotes, hasLength(2));
      final aapl = quotes.first;
      expect(aapl.symbol, 'AAPL');
      expect(aapl.name, 'Apple Inc.');
      expect(aapl.lastPrice, closeTo(275.93, 1e-9));
      expect(aapl.change, closeTo(0.78, 1e-9));
      expect(aapl.changePercent, closeTo(0.28, 1e-9));
      expect(aapl.volume, 51234567);
      expect(aapl.marketCap, 4200000000000);
      expect(aapl.isUp, isTrue);

      final spx = quotes.last;
      expect(spx.symbol, '^GSPC');
      expect(spx.isIndex, isTrue);
      expect(spx.marketState, 'CLOSED');
    });
  });

  group('format helpers', () {
    test('prices keep two decimals by default and trim when disabled', () {
      expect(priceText(1234.5), '1,234.50');
      expect(priceText(1234.5, roundTwoDp: false), '1,234.5');
      expect(signedAmount(-5.6), '-5.60');
      expect(signedAmount(12.3), '+12.30');
    });

    test('percent and compact formats', () {
      expect(percentText(0.16), '+0.16%');
      expect(percentText(-1.2), '-1.20%');
      expect(compactNumber(51234567), '51.23M');
      expect(compactNumber(4200000000000), '4.2T');
    });

    test('currency symbols', () {
      expect(currencySymbol('USD'), r'$');
      expect(currencySymbol('EUR'), '€');
      expect(currencySymbol('CNY'), 'CN¥');
    });
  });
}
