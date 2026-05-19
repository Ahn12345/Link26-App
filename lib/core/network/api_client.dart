import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../domain/failure.dart';
import '../domain/result.dart';
import '../storage/token_storage.dart';
import '../utils/logger.dart';
import 'network_error_mapper.dart';

/// 공용 HTTP: [get]/[post] 는 기존 통합 API(NHIS·DUR 등)용 [Uri] 호출.
/// REST 백엔드용 상대 경로는 [dio] 인스턴스를 사용하세요.
class ApiClient {
  ApiClient();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final h = options.headers;
          final hasAuth = h.map((k, v) => MapEntry(k.toLowerCase(), v)).containsKey('authorization');
          if (!hasAuth) {
            final token = await TokenStorage().getToken();
            if (token != null && token.isNotEmpty) {
              h['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );

  final Dio _dioForUri = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<Result<String>> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await _dioForUri.getUri<dynamic>(
        uri,
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data is String) return Success(data);
      return Success(jsonEncode(data));
    } on DioException catch (e, st) {
      appLog('GET failed', error: e, stack: st);
      return Failure(AppFailure('GET 오류: ${e.message}', cause: e));
    } catch (e, st) {
      appLog('GET failed', error: e, stack: st);
      return Failure(mapHttpException(e, st));
    }
  }

  Future<Result<String>> post(
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dioForUri.postUri<dynamic>(
        uri,
        data: body,
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data is String) return Success(data);
      return Success(jsonEncode(data));
    } on DioException catch (e, st) {
      appLog('POST failed', error: e, stack: st);
      return Failure(AppFailure('POST 오류: ${e.message}', cause: e));
    } catch (e, st) {
      appLog('POST failed', error: e, stack: st);
      return Failure(mapHttpException(e, st));
    }
  }

  void close() {
    _dioForUri.close();
  }
}
