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
  }) async {
    final base = NhisRuntimeConfig.baseUrl;
    if (base.isEmpty) {
      return const Failure(_missing);
    }

    var uri = buildUri(NhisRuntimeConfig.medicinesPath, base: base);
    final q = Map<String, String>.from(uri.queryParameters);
    q['phone'] = phoneDigits;
    final key = NhisRuntimeConfig.serviceKey;
    if (key != null) {
      q['serviceKey'] = key;
    }
    uri = uri.replace(queryParameters: q);

    return _api.get(uri, headers: await _headers.headers());
  }
}
