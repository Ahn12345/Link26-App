import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/network_error_mapper.dart';
import '../../core/network/nhis_token_manager.dart';
import 'nhis_runtime_config.dart';

/// NHIS/BFF에서 로그인 사용자 복약 목록을 가져옵니다.
///
/// 홈 부팅 시 자주 호출되므로 [ApiClient] 기본(30/45초)보다 짧은 타임아웃을 씁니다.
class NhisMedicationsClient {
  NhisMedicationsClient({
    NhisTokenManager? tokens,
  }) : _headers = AuthHeaderBuilder(tokens ?? NhisTokenManager());

  final AuthHeaderBuilder _headers;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 18),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static const AppFailure _missing =
      AppFailure('NHIS_BASE_URL 이 비어 있습니다.', code: 'NHIS_CONFIG');

  Future<Result<String>> fetchMedicationsRaw({
    required String phoneDigits,
    String? displayName,
    String? gender,
    String? connectedId,
  }) async {
    final base = NhisRuntimeConfig.baseUrl;
    if (base.isEmpty) {
      return const Failure(_missing);
    }

    var uri = buildUri(NhisRuntimeConfig.medicinesPath, base: base);
    final q = Map<String, String>.from(uri.queryParameters);
    q['phone'] = phoneDigits;
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) q['displayName'] = dn;
    final g = gender?.trim();
    if (g != null && g.isNotEmpty) q['gender'] = g;
    final cid = connectedId?.trim();
    if (cid != null && cid.isNotEmpty) q['connectedId'] = cid;
    final key = NhisRuntimeConfig.serviceKey;
    if (key != null) {
      q['serviceKey'] = key;
    }
    uri = uri.replace(queryParameters: q);

    try {
      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(headers: await _headers.headers()),
      );
      final data = response.data;
      if (data is String) return Success(data);
      return Success(jsonEncode(data));
    } on DioException catch (e) {
      return Failure(AppFailure('GET 오류: ${e.message}', cause: e));
    } catch (e, st) {
      return Failure(mapHttpException(e, st));
    }
  }
}
