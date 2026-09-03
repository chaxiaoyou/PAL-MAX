import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/quote.dart';

/// Client for the same Yahoo Finance endpoints the open-source Stocks Widget
/// uses: quotes (v7), historical charts (v8), symbol search (v1) and the RSS
/// news feed. Yahoo requires browser-like cookies plus a crumb token for the
/// quote API, so this service performs the same bootstrap flow as the original
/// app: load finance.yahoo.com (following the GDPR consent redirect), scrape
/// the csrf token, submit the consent form, then fetch `/v1/test/getcrumb`.
class YahooFinanceApi {
  YahooFinanceApi() {
    _client.userAgent = _userAgent;
  }

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/115.0.0.0 Safari/537.36';

  /// Browser-like Accept header Yahoo Finance expects; a bare `*/*` makes the
  /// API hosts treat the client as a non-browser.
  static const _acceptHeader =
      'text/html,application/xhtml+xml,application/xml;q=0.9,'
      'image/webp,image/apng,*/*;q=0.8,'
      'application/signed-exchange;v=b3;q=0.7';

  static const _consentHost = 'guce.yahoo.com';
  static const _financeHome = 'https://finance.yahoo.com/';
  static const _quoteBase = 'https://query1.finance.yahoo.com/';
  static const _searchBase = 'https://query2.finance.yahoo.com/v1/finance/';
  static const _newsBase = 'https://feeds.finance.yahoo.com/rss/2.0/headline';

  final HttpClient _client = HttpClient();
  final Map<String, _StoredCookie> _cookies = {};
  String? _crumb;
  bool _disposed = false;

  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const [];
    if (_crumb == null) {
      await _bootstrap();
    }
    for (var attempt = 0; attempt < 3; attempt++) {
      final uri = Uri.parse('${_quoteBase}v7/finance/quote').replace(
        queryParameters: {
          'format': 'json',
          'symbols': symbols.join(','),
          if (_crumb != null) 'crumb': _crumb!,
        },
      );
      final response = await _get(uri);
      if (response.statusCode == 200) {
        Object? decoded;
        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          decoded = null;
        }
        final map = decoded is Map<String, dynamic> ? decoded : null;
        final result = map?['quoteResponse']?['result'];
        if (result is List) {
          final quotes = result
              .whereType<Map<String, dynamic>>()
              .map(Quote.fromYahooJson)
              .where((q) => q.symbol.isNotEmpty)
              .toList();
          if (quotes.isNotEmpty) {
            return _inWatchlistOrder(quotes, symbols);
          }
        }
        if (_crumb == null) {
          // An empty 200 response before a crumb is stored behaves like a 401.
          await _bootstrap();
          continue;
        }
        // Genuinely no results for these symbols.
        return const [];
      }
      if (response.statusCode == 401) {
        debugPrint('[yahoo] quote 401 (attempt ${attempt + 1}): '
            '${_preview(response.body)}');
        _crumb = null;
        await _bootstrap();
        continue;
      }
      throw YahooFinanceException(
        'Quotes request failed with HTTP ${response.statusCode}',
      );
    }
    throw const YahooFinanceException('Unable to fetch quotes');
  }

  Future<List<Quote>> fetchQuote(String symbol) async {
    final quotes = await fetchQuotes([symbol]);
    if (quotes.isEmpty) {
      throw const YahooFinanceException('Symbol not found');
    }
    return quotes;
  }

  Future<List<ChartPoint>> fetchChart(
    String symbol, {
    required String range,
    required String interval,
  }) async {
    final encoded = Uri.encodeComponent(symbol);
    final uri = Uri.parse('${_quoteBase}v8/finance/chart/$encoded').replace(
      queryParameters: {
        'range': range,
        'interval': interval,
        if (_crumb != null) 'crumb': _crumb!,
      },
    );
    final response = await _getWithAuthRetry(uri);
    if (response.statusCode != 200) {
      throw YahooFinanceException(
        'Chart request failed with HTTP ${response.statusCode}',
      );
    }
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    final chart = (decoded is Map<String, dynamic>)
        ? decoded['chart']
        : null;
    final rawResult =
        (chart is Map<String, dynamic>) ? chart['result'] : null;
    if (rawResult is! List || rawResult.isEmpty) {
      throw const YahooFinanceException('No chart data available');
    }
    final first = rawResult.first;
    if (first is! Map<String, dynamic>) {
      throw const YahooFinanceException('No chart data available');
    }
    final timestamps = first['timestamp'];
    final closes = first['indicators']?['quote']?[0]?['close'];
    if (timestamps is! List || closes is! List) {
      throw const YahooFinanceException('No chart data available');
    }
    final points = <ChartPoint>[];
    for (var i = 0; i < timestamps.length && i < closes.length; i++) {
      final ts = timestamps[i];
      final close = closes[i];
      if (ts is int && close is num && close.toDouble().isFinite) {
        points.add(
          ChartPoint(time: ts, close: close.toDouble()),
        );
      }
    }
    return points;
  }

  Future<List<SearchResult>> search(String query) async {
    final uri = Uri.parse('${_searchBase}search').replace(
      queryParameters: {
        'q': query,
        'quotesCount': '20',
        'newsCount': '0',
        'listsCount': '0',
        'enableFuzzyQuery': 'false',
      },
    );
    final response = await _getWithAuthRetry(uri);
    if (response.statusCode != 200) {
      throw YahooFinanceException(
        'Search request failed with HTTP ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    final list = (decoded is Map<String, dynamic>) ? decoded['quotes'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SearchResult.fromYahooJson)
        .where((r) => r.symbol.isNotEmpty)
        .toList();
  }

  Future<List<NewsItem>> fetchNews(String symbol) async {
    final uri = Uri.parse(_newsBase).replace(
      queryParameters: {
        's': symbol,
        'region': 'US',
        'lang': 'en-US',
      },
    );
    final response = await _get(uri);
    if (response.statusCode != 200) return const [];
    return _parseRss(response.body);
  }

  Future<void> _bootstrap() async {
    final home = await _get(Uri.parse(_financeHome));
    final html = home.body;
    final finalUrl = home.finalUrl;
    final csrf = _extractCsrf(html, finalUrl);
    final consent =
        finalUrl.host.contains(_consentHost) || html.contains('csrfToken');
    debugPrint('[yahoo] bootstrap home: HTTP ${home.statusCode} '
        'final=${finalUrl.host}${finalUrl.path} '
        'csrf=${csrf != null} cookies=${_cookies.keys.join(',')}');
    if (consent) {
      final uri = finalUrl;
      final sessionId = uri.queryParameters['sessionId'] ??
          (finalUrl.pathSegments.isEmpty
              ? ''
              : finalUrl.pathSegments.last);
      if (csrf != null && csrf.isNotEmpty && sessionId.isNotEmpty) {
        final body =
            'csrfToken=${Uri.encodeQueryComponent(csrf)}'
            '&sessionId=${Uri.encodeQueryComponent(sessionId)}'
            '&originalDoneUrl=${Uri.encodeQueryComponent('https://finance.yahoo.com/?guccounter=1')}'
            '&namespace=yahoo'
            '&agree=agree';
        final consentResponse = await _post(uri, body: body);
        debugPrint('[yahoo] consent POST: HTTP ${consentResponse.statusCode}');
        // Some Yahoo regions only copy the session cookies after an explicit
        // copyConsent round-trip; harmless when unnecessary.
        final copyUri = Uri.parse('https://guce.yahoo.com/copyConsent')
            .replace(queryParameters: {'sessionId': sessionId});
        final copyResponse = await _get(copyUri);
        debugPrint('[yahoo] copyConsent: HTTP ${copyResponse.statusCode}');
      } else {
        debugPrint('[yahoo] consent page without csrf/sessionId, skipping');
      }
    }
    for (final host in const [
      'query1.finance.yahoo.com',
      'query2.finance.yahoo.com',
    ]) {
      final crumbResponse =
          await _get(Uri.parse('https://$host/v1/test/getcrumb'));
      final crumbBody = crumbResponse.body.trim();
      debugPrint('[yahoo] getcrumb($host): HTTP ${crumbResponse.statusCode} '
          'len=${crumbBody.length} body=${_preview(crumbBody)}');
      if (crumbResponse.statusCode == 200 && _looksLikeCrumb(crumbBody)) {
        _crumb = crumbBody;
        return;
      }
    }
    _crumb = null;
    throw const YahooFinanceException(
      'Crumb bootstrap failed: no valid crumb from query1/query2',
    );
  }

  /// Real crumbs are short base64-ish tokens; when Yahoo serves a block page
  /// or JSON error with HTTP 200 this rejects it instead of caching garbage.
  bool _looksLikeCrumb(String value) {
    if (value.isEmpty || value.length > 256) return false;
    if (value.contains('<') || value.contains('>')) return false;
    return RegExp(r'^[A-Za-z0-9+/=_.%~-]+$').hasMatch(value);
  }

  String _preview(String value, [int max = 120]) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= max) return collapsed;
    return '${collapsed.substring(0, max)}...';
  }

  String? _extractCsrf(String html, Uri consentUri) {
    final value = consentUri.queryParameters['csrfToken'];
    if (value != null && value.isNotEmpty) return value;
    final match = RegExp(r'csrfToken" value="([^"]+)"').firstMatch(html);
    return match?.group(1);
  }

  List<Quote> _inWatchlistOrder(List<Quote> quotes, List<String> symbols) {
    final bySymbol = {for (final quote in quotes) quote.symbol: quote};
    final ordered = <Quote>[];
    for (final symbol in symbols) {
      final quote = bySymbol[symbol];
      if (quote != null) ordered.add(quote);
    }
    return ordered;
  }

  Future<_HttpResult> _get(Uri uri) => _send('GET', uri);

  /// Yahoo occasionally requires a fresh crumb/session (HTTP 401). Retry once
  /// after re-bootstrapping instead of surfacing an error to the UI.
  Future<_HttpResult> _getWithAuthRetry(Uri uri) async {
    var response = await _get(uri);
    if (response.statusCode == 401 && _crumb != null) {
      debugPrint('[yahoo] 401 ${uri.path}: ${_preview(response.body)}');
      _crumb = null;
      try {
        await _bootstrap();
      } on YahooFinanceException {
        return response;
      }
      response = await _get(uri);
      if (response.statusCode == 401) {
        debugPrint('[yahoo] retry still 401 ${uri.path}: '
            '${_preview(response.body)}');
      }
    }
    return response;
  }

  Future<_HttpResult> _post(Uri uri, {required String body}) {
    return _send('POST', uri, body: body);
  }

  Future<_HttpResult> _send(
    String method,
    Uri uri, {
    String? body,
    int redirectsLeft = 10,
  }) async {
    final request = await _client.openUrl(method, uri);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
    request.headers.set(HttpHeaders.acceptHeader, _acceptHeader);
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    final cookieHeader = _cookieHeaderFor(uri.host);
    if (cookieHeader.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }
    if (body != null) {
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      request.write(body);
    }

    final response = await request.close();
    _storeCookies(uri, response);
    final headers = response.headers;
    final location = headers.value(HttpHeaders.locationHeader);
    final code = response.statusCode;
    if (code >= 300 && code < 400 && location != null && redirectsLeft > 0) {
      await response.drain<void>();
      // Match browser/OkHttp semantics: 301/302/303 turn a POST into a GET,
      // otherwise the consent redirect would re-submit the form to
      // finance.yahoo.com and never receive the session cookies.
      final redirectAsGet = method != 'GET' &&
          method != 'HEAD' &&
          (code == HttpStatus.movedPermanently ||
              code == HttpStatus.found ||
              code == HttpStatus.seeOther);
      return _send(
        redirectAsGet ? 'GET' : method,
        uri.resolve(location),
        body: redirectAsGet ? null : body,
        redirectsLeft: redirectsLeft - 1,
      );
    }
    final text = await utf8.decoder.bind(response).join();
    return _HttpResult(
      statusCode: code,
      body: text,
      finalUrl: uri,
    );
  }

  String _cookieHeaderFor(String host) {
    final parts = <String>[];
    for (final entry in _cookies.values) {
      if (!_hostMatches(host, entry.domain)) continue;
      final expires = entry.expires;
      if (expires != null && expires.isBefore(DateTime.now().toUtc())) {
        continue;
      }
      parts.add('${entry.name}=${entry.value}');
    }
    return parts.join('; ');
  }

  bool _hostMatches(String host, String domain) {
    if (domain == host) return true;
    return host.endsWith('.$domain');
  }

  void _storeCookies(Uri origin, HttpClientResponse response) {
    final setCookies = response.headers[HttpHeaders.setCookieHeader];
    if (setCookies == null) return;
    for (final value in setCookies) {
      try {
        final cookie = Cookie.fromSetCookieValue(value);
        var domain = cookie.domain;
        if (domain == null || domain.isEmpty) {
          domain = origin.host;
        }
        domain = domain.startsWith('.') ? domain.substring(1) : domain;
        _cookies[cookie.name] = _StoredCookie(
          name: cookie.name,
          value: cookie.value,
          domain: domain,
          expires: cookie.expires,
        );
      } on FormatException {
        // Ignore malformed cookies.
      }
    }
  }

  static List<NewsItem> _parseRss(String xml) {
    final items = <NewsItem>[];
    final itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
    for (final match in itemPattern.allMatches(xml)) {
      final block = match.group(1) ?? '';
      String field(String tag) {
        final found = RegExp(
          '<$tag(?:\\s[^>]*)?>(.*?)</$tag>',
          dotAll: true,
        ).firstMatch(block);
        return found?.group(1)?.trim() ?? '';
      }

      final title = _stripHtml(field('title'));
      final link = field('link');
      if (title.isEmpty || link.isEmpty) continue;
      final rawDate = field('pubDate');
      DateTime? date;
      try {
        date = HttpDate.parse(rawDate);
      } catch (_) {
        date = null;
      }
      items.add(
        NewsItem(
          title: title,
          link: link,
          description: _stripHtml(field('description')),
          pubDate: date ?? DateTime.now(),
        ),
      );
    }
    return items;
  }

  static String _stripHtml(String input) =>
      input.replaceAll(RegExp(r'<[^>]+>'), '').trim();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _client.close(force: true);
  }
}

class _StoredCookie {
  _StoredCookie({
    required this.name,
    required this.value,
    required this.domain,
    this.expires,
  });

  final String name;
  final String value;
  final String domain;
  final DateTime? expires;
}

class _HttpResult {
  _HttpResult({
    required this.statusCode,
    required this.body,
    required this.finalUrl,
  });

  final int statusCode;
  final String body;
  final Uri finalUrl;
}

class YahooFinanceException implements Exception {
  const YahooFinanceException(this.message);

  final String message;

  @override
  String toString() => message;
}
