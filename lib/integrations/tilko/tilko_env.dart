import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/integrations/tilko/tilko_env_resolver.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

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

  /// 간편인증 채널 — 현재 제품은 카카오만 (`TILKO_PRIVATE_AUTH_TYPE=KAKAO`).
  static String get privateAuthType {
    final s = (dotenv.env['TILKO_PRIVATE_AUTH_TYPE'] ?? 'KAKAO').trim();
    return s.isEmpty ? 'KAKAO' : s;
  }

  /// BFF·틸코 요청 본문용 채널 이름(항상 `KAKAO`).
  static String get privateAuthTypePlain =>
      tilkoPrivateAuthTypePlain(privateAuthType);

  static bool get isKakaoAuthOnly =>
      tilkoPrivateAuthTypeName(privateAuthType) == 'KAKAO';

  static bool get isConfigured => apiKey.isNotEmpty;
}
