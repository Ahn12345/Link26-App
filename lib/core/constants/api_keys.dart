/// 민감 값은 .env + --dart-define 권장. 여기서는 키 이름만 노출.
abstract final class ApiConfig {
  /// 개발용 `--dart-define=NHIS_BASE_URL=...` (디버그에서 dotenv 없을 때 보조).
  static const nhisBaseUrl = String.fromEnvironment('NHIS_BASE_URL', defaultValue: '');

  /// **스토어 릴리스 전용.** PC BFF LAN 주소가 dotenv에 박혀 있어도 릴리스에서는 무시하고
  /// 이 값만 씁니다. 빌드: `--dart-define=NHIS_PRODUCTION_BASE_URL=https://api.example.com`
  static const nhisProductionBaseUrl =
      String.fromEnvironment('NHIS_PRODUCTION_BASE_URL', defaultValue: '');

  /// 릴리스에서 [Link26RemoteBffBootstrap] 이 JSON을 받아올 **매니페스트 URL** (HTTPS).
  /// dotenv `LINK26_REMOTE_CONFIG_URL` 또는 `--dart-define=LINK26_REMOTE_CONFIG_URL=...`
  static const link26RemoteConfigUrl =
      String.fromEnvironment('LINK26_REMOTE_CONFIG_URL', defaultValue: '');
  static const durBaseUrl = String.fromEnvironment('DUR_BASE_URL', defaultValue: '');
  static const medicineOverviewBaseUrl =
      String.fromEnvironment('MEDICINE_OVERVIEW_BASE_URL', defaultValue: '');
  static const simpleAuthBaseUrl =
      String.fromEnvironment('SIMPLE_AUTH_BASE_URL', defaultValue: '');
  /// Google AI Studio / Gemini. 빌드 시 `--dart-define=GEMINI_API_KEY=...` 또는 `.env` 의 GEMINI_API_KEY ([GeminiRuntimeConfig]).
  static const geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
