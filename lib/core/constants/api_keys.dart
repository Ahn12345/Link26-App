/// 민감 값은 .env + --dart-define 권장. 여기서는 키 이름만 노출.
abstract final class ApiConfig {
  static const nhisBaseUrl = String.fromEnvironment('NHIS_BASE_URL', defaultValue: '');
  static const durBaseUrl = String.fromEnvironment('DUR_BASE_URL', defaultValue: '');
  static const medicineOverviewBaseUrl =
      String.fromEnvironment('MEDICINE_OVERVIEW_BASE_URL', defaultValue: '');
  static const simpleAuthBaseUrl =
      String.fromEnvironment('SIMPLE_AUTH_BASE_URL', defaultValue: '');
}
