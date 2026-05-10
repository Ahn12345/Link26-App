import '../constants/api_keys.dart';

/// 통합 엔드포인트 조립 (baseUrl 비어 있으면 호출 시 실패 처리).
Uri buildUri(String path, {Map<String, String>? query, required String base}) {
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final p = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$root$p').replace(queryParameters: query);
}

Uri nhisUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.nhisBaseUrl);

Uri durUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.durBaseUrl);

Uri medicineOverviewUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.medicineOverviewBaseUrl);

Uri simpleAuthUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.simpleAuthBaseUrl);

/// Dio [ApiClient.dio] 의 `baseUrl` + 상대 경로 (`.env` 의 `API_BASE_URL`).
abstract final class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const me = '/auth/me';
  static const logout = '/auth/logout';

  static const homeDashboard = '/home/dashboard';
  static const medicines = '/medicines';
  static const alarms = '/alarms';
  static const familyMembers = '/family/members';
  static const notificationSettings = '/settings/notifications';
  static const displaySettings = '/settings/display';
  static const aiChat = '/ai/chat';
  static const aiPrescription = '/ai/prescription';
}
