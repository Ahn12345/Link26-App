import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../domain/result.dart';
import '../utils/logger.dart';
import 'network_error_mapper.dart';

/// 공용 HTTP 클라이언트.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<Result<String>> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final res = await _http
          .get(uri, headers: headers)
          .timeout(AppConstants.defaultTimeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Success(utf8.decode(res.bodyBytes));
      }
      return Failure(mapStatusCode(res.statusCode, res.body));
    } catch (e, st) {
      appLog('GET failed', error: e, stack: st);
      return Failure(mapHttpException(e, st));
    }
  }

  Future<Result<String>> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final res = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              ...?headers,
            },
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(AppConstants.defaultTimeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Success(utf8.decode(res.bodyBytes));
      }
      return Failure(mapStatusCode(res.statusCode, res.body));
    } catch (e, st) {
      appLog('POST failed', error: e, stack: st);
      return Failure(mapHttpException(e, st));
    }
  }

  void close() => _http.close();
}
