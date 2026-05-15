import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/integrations/tilko/tilko_env_resolver.dart';

/// 앱 전용 — `assets/env/dotenv`의 틸코 설정 (BFF는 [loadBffDotEnv] + resolver).
abstract final class TilkoEnv {
  static Map<String, String> get _resolved {
    final m = Map<String, String>.from(dotenv.env);
    TilkoEnvResolver.applyTo(m);
    return m;
  }

  static String get apiKey => (_resolved['TILKO_API_KEY'] ?? '').trim();

  static String get apiHost =>
      (_resolved['TILKO_API_HOST'] ?? TilkoEnvResolver.demoHost).trim();

  /// 간편인증 채널 (KAKAO, NAVER, PASS …). `.env` / `assets/env/dotenv` 의 `TILKO_PRIVATE_AUTH_TYPE`.
  static String get privateAuthType {
    final s = (dotenv.env['TILKO_PRIVATE_AUTH_TYPE'] ?? 'KAKAO').trim();
    return s.isEmpty ? 'KAKAO' : s;
  }

  static bool get isConfigured => apiKey.isNotEmpty;
}
