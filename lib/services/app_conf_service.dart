import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Mirrors the uni-app `fetchAppConf` request:
/// `GET {base}/member/reg_conf?id=27&platform=android`.
///
/// Returns the backend-provided `steer` URL when the native app should be
/// replaced by a web page, or `null` when the app should run normally.
class AppConfService {
  AppConfService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'BASE_URL',
              defaultValue: 'https://stapi.palpuls.com',
            );

  final String baseUrl;

  static const _timeout = Duration(seconds: 15);

  Future<String?> fetchSteerUrl() async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    final root = baseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$root/member/reg_conf').replace(
      queryParameters: {'type': platform},
    );

    final response = await http
        .get(uri, headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Platform': 'client',
          'Lan': 'en',
          'Version': '3',
        })
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'reg_conf returned HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('reg_conf returned invalid JSON');
    }

    final data = (body is Map<String, dynamic>) ? body['data'] : null;
    final steer = (data is Map<String, dynamic>) ? data['steer'] : '';
    // final steer = 'https://starv.hscrespro.com';
    return (steer is String && steer.isNotEmpty) ? steer : null;
  }
}
