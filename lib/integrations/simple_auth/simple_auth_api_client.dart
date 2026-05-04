import '../../core/constants/api_keys.dart';
import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'simple_auth_endpoints.dart';
import 'simple_auth_request_models.dart';

class SimpleAuthApiClient {
  SimpleAuthApiClient({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const AppFailure _missing =
      AppFailure('SIMPLE_AUTH_BASE_URL 이 설정되지 않았습니다.', code: 'AUTH_CONFIG');

  Future<Result<String>> startRaw(SimpleAuthStartRequest req) async {
    if (ApiConfig.simpleAuthBaseUrl.isEmpty) {
      return const Failure(_missing);
    }
    final uri = simpleAuthUri(SimpleAuthEndpoints.start);
    return _api.post(uri, body: req.toJson());
  }
}
