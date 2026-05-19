import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/network_error_mapper.dart';
import '../../core/network/nhis_token_manager.dart';
import 'package:link26_app/core/services/link26_bff_reachability.dart';

import 'nhis_http_message.dart';
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
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static const AppFailure _missing =
      AppFailure('NHIS_BASE_URL 이 비어 있습니다.', code: 'NHIS_CONFIG');

  static String _dioErrorDetail(DioException e) {
    final m = e.message?.trim();
    if (m != null && m.isNotEmpty) return m;
    final err = e.error;
    if (err != null) {
      final s = '$err'.trim();
      if (s.isNotEmpty) return s;
    }
    return '${e.type}';
  }

  Future<Result<String>> fetchMedicationsRaw({
    required String phoneDigits,
    String? displayName,
    String? gender,
    String? connectedId,
  }) async {
    var bases = Link26BffReachability.reachableOnly(
      Link26BffReachability.lastOrderedBases,
    );
    if (bases.isEmpty && Link26BffReachability.recentlyAllUnreachable) {
      return const Failure(_missing);
    }
    if (bases.isEmpty) {
      bases = NhisRuntimeConfig.baseUrlCandidates;
    }
    if (bases.isEmpty) {
      return const Failure(_missing);
    }

    final headers = await _headers.headers();
    DioException? lastDio;
    Object? lastOther;
    StackTrace? lastSt;

    bool hasAnotherNonEmptyBase(int i) {
      for (var j = i + 1; j < bases.length; j++) {
        if (bases[j].trim().isNotEmpty) return true;
      }
      return false;
    }

    for (var bi = 0; bi < bases.length; bi++) {
      final base = bases[bi].trim();
      if (base.isEmpty) continue;

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
          options: Options(headers: headers),
        );
        final data = response.data;
        if (data is String) return Success(data);
        return Success(jsonEncode(data));
      } on DioException catch (e) {
        lastDio = e;
        if (hasAnotherNonEmptyBase(bi) && dioExceptionLooksUnreachable(e)) {
          continue;
        }
        return Failure(AppFailure('GET 오류: ${_dioErrorDetail(e)}', cause: e));
      } catch (e, st) {
        lastOther = e;
        lastSt = st;
        if (hasAnotherNonEmptyBase(bi) && link26ErrorLooksLikeUnreachableHost(e)) {
          continue;
        }
        return Failure(mapHttpException(e, st));
      }
    }

    if (lastDio != null) {
      return Failure(
        AppFailure('GET 오류: ${_dioErrorDetail(lastDio)}', cause: lastDio),
      );
    }
    if (lastOther != null && lastSt != null) {
      return Failure(mapHttpException(lastOther, lastSt));
    }
    return const Failure(_missing);
  }
}
