import '../../core/constants/api_keys.dart';
import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/nhis_token_manager.dart';
import 'nhis_endpoints.dart';

class NhisApiClient {
  NhisApiClient({
    ApiClient? api,
    NhisTokenManager? tokens,
  })  : _api = api ?? ApiClient(),
        _headers = AuthHeaderBuilder(tokens ?? NhisTokenManager());

  final ApiClient _api;
  final AuthHeaderBuilder _headers;

  static const AppFailure _missing =
      AppFailure('NHIS_BASE_URL 이 설정되지 않았습니다.', code: 'NHIS_CONFIG');

  Future<Result<String>> fetchUserProfileRaw() async {
    if (ApiConfig.nhisBaseUrl.isEmpty) {
      return const Failure(_missing);
    }
    final uri = nhisUri(NhisEndpoints.userProfile);
    return _api.get(uri, headers: await _headers.headers());
  }
}
