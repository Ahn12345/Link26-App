import '../../core/constants/api_keys.dart';
import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'medicine_overview_endpoints.dart';
import 'medicine_overview_request_models.dart';

class MedicineOverviewApiClient {
  MedicineOverviewApiClient({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const AppFailure _missing =
      AppFailure('MEDICINE_OVERVIEW_BASE_URL 이 설정되지 않았습니다.', code: 'MED_CONFIG');

  Future<Result<String>> searchRaw(MedicineSearchRequest req) async {
    if (ApiConfig.medicineOverviewBaseUrl.isEmpty) {
      return const Failure(_missing);
    }
    final uri = medicineOverviewUri(
      MedicineOverviewEndpoints.search,
      query: {'q': req.query},
    );
    return _api.get(uri);
  }
}
