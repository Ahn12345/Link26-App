import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/nhis_token_manager.dart';
import 'nhis_runtime_config.dart';

/// NHIS/BFF에서 로그인 사용자 복약 목록을 가져옵니다.
class NhisMedicationsClient {
  NhisMedicationsClient({
    ApiClient? api,
    NhisTokenManager? tokens,
  })  : _api = api ?? ApiClient(),
        _headers = AuthHeaderBuilder(tokens ?? NhisTokenManager());

  final ApiClient _api;
  final AuthHeaderBuilder _headers;

  static const AppFailure _missing =
      AppFailure('NHIS_BASE_URL 이 비어 있습니다.', code: 'NHIS_CONFIG');

  Future<Result<String>> fetchMedicationsRaw({
    required String phoneDigits,
    /// 로컬 DB 사용자 — BFF·CODEF가 상품 스펙에 따라 본인 매칭에 쓸 수 있음
    String? displayName,
    String? gender,
    /// CODEF 기관 연동 식별자 — BFF가 상품 POST에 넣습니다.
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

    return _api.get(uri, headers: await _headers.headers());
  }
}
