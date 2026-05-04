import '../../core/constants/api_keys.dart';
import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'dur_endpoints.dart';
import 'dur_request_models.dart';

class DurApiClient {
  DurApiClient({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const AppFailure _missing =
      AppFailure('DUR_BASE_URL 이 설정되지 않았습니다.', code: 'DUR_CONFIG');

  Future<Result<String>> checkRaw(DurCheckRequest req) async {
    if (ApiConfig.durBaseUrl.isEmpty) {
      return const Failure(_missing);
    }
    final uri = durUri(DurEndpoints.check);
    return _api.post(uri, body: req.toJson());
  }
}
