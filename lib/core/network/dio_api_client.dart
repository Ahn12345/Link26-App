import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 카카오 functional 프로젝트의 Dio 기반 클라이언트.
/// 기존 [ApiClient](http 기반)와 병행 — NHIS/DUR 등은 기존 클라이언트 사용.
abstract final class DioApiClient {
  DioApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
}
