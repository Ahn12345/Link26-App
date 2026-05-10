import 'package:dio/dio.dart';

import 'package:link26_app/core/network/api_client.dart';
import 'package:link26_app/core/network/api_endpoints.dart';

class AuthApiService {
  AuthApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.signup,
      data: {'name': name, 'email': email, 'password': password},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.me);
    return _asMap(response.data);
  }

  Future<void> logout() async {
    await _dio.post<dynamic>(ApiEndpoints.logout);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{'data': data};
  }
}
