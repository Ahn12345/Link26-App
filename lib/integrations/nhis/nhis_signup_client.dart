import '../../core/domain/failure.dart';
import '../../core/domain/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'nhis_runtime_config.dart';

/// 국민건강보험공단·자체 게이트웨이 등에 회원 정보를 등록할 때 사용.
/// 실제 URL·바디는 백엔드 스펙에 맞게 조정하세요. 주민번호는 **해시만** 전송합니다.
class NhisSignupClient {
  NhisSignupClient({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<Result<String>> submitRegistration({
    required String displayName,
    required String phoneDigits,
    required String gender,
    required String residentRegistrationHash,
  }) async {
    final base = NhisRuntimeConfig.baseUrl;
    if (base.isEmpty) {
      return const Failure(
        AppFailure('NHIS_BASE_URL 이 비어 있습니다.', code: 'NHIS_CONFIG'),
      );
    }

    var uri = buildUri(NhisRuntimeConfig.signupPath, base: base);
    final key = NhisRuntimeConfig.serviceKey;
    if (key != null) {
      final q = Map<String, String>.from(uri.queryParameters);
      q['serviceKey'] = key;
      uri = uri.replace(queryParameters: q);
    }

    return _api.post(
      uri,
      body: {
        'displayName': displayName,
        'phone': phoneDigits,
        'gender': gender,
        'residentRegistrationHash': residentRegistrationHash,
        'privacyConsent': true,
      },
    );
  }
}
