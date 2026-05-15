/// BFF·앱 공통 — 틸코 데모/운영 호스트·키 짝을 `.env`에서 맞춥니다.
///
/// 한 API Key로 다음 3 상품을 모두 호출합니다(호스트만 데모/운영 구분).
/// - `hirasimpleauth/*` (심평원 간편인증)
/// - `nhissimpleauth/*` (건강보험공단 간편인증)
/// - HIRA 내가 먹는 약 / NHIS 진료·투약 조회
abstract final class TilkoEnvResolver {
  static const demoHost = 'https://dev.tilko.net';
  static const prodHost = 'https://api.tilko.net';

  static bool useProduction(Map<String, String> env) {
    final flag = (env['TILKO_USE_PRODUCTION'] ?? env['TILKO_ENV'] ?? '')
        .trim()
        .toLowerCase();
    if (flag == 'true' ||
        flag == '1' ||
        flag == 'yes' ||
        flag == 'production' ||
        flag == 'prod' ||
        flag == '운영') {
      return true;
    }
    if (flag == 'false' ||
        flag == '0' ||
        flag == 'demo' ||
        flag == 'development' ||
        flag == 'dev' ||
        flag == '데모') {
      return false;
    }
    final host = (env['TILKO_API_HOST'] ?? '').trim().toLowerCase();
    if (host.contains('api.tilko.net')) return true;
    if (host.contains('dev.tilko.net')) return false;
    return false;
  }

  static String resolveHost(Map<String, String> env) {
    if (useProduction(env)) return prodHost;
    final explicit = (env['TILKO_API_HOST'] ?? '').trim();
    if (explicit.isNotEmpty) return explicit;
    return demoHost;
  }

  static String resolveApiKey(Map<String, String> env) {
    if (useProduction(env)) {
      final prod = (env['TILKO_API_KEY_PROD'] ??
              env['TILKO_API_KEY_PRODUCTION'] ??
              '')
          .trim();
      if (prod.isNotEmpty) return prod;
      return (env['TILKO_API_KEY'] ?? '').trim();
    }
    final demo = (env['TILKO_API_KEY_DEMO'] ?? '').trim();
    if (demo.isNotEmpty) return demo;
    return (env['TILKO_API_KEY'] ?? '').trim();
  }

  static bool productionKeyMissing(Map<String, String> env) =>
      useProduction(env) &&
      (env['TILKO_API_KEY_PROD'] ?? '').trim().isEmpty &&
      (env['TILKO_API_KEY'] ?? '').trim().isEmpty;

  /// `TILKO_API_HOST`·`TILKO_API_KEY`를 활성 환경 값으로 덮어씁니다.
  static void applyTo(Map<String, String> env) {
    env['TILKO_API_HOST'] = resolveHost(env);
    env['TILKO_API_KEY'] = resolveApiKey(env);
  }

  static String modeLabelKo(Map<String, String> env) =>
      useProduction(env) ? '운영' : '데모';
}
