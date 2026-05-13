import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 전용 — `.env`의 틸코 설정 (BFF는 [TilkoHiraSimpleAuthClient.fromBffEnv] 사용).
abstract final class TilkoEnv {
  static String get apiKey => (dotenv.env['TILKO_API_KEY'] ?? '').trim();

  static String get apiHost =>
      (dotenv.env['TILKO_API_HOST'] ?? 'https://dev.tilko.net').trim();

  /// 간편인증 채널 (KAKAO, NAVER, PASS …). `.env` / `assets/env/dotenv` 의 `TILKO_PRIVATE_AUTH_TYPE`.
  static String get privateAuthType {
    final s = (dotenv.env['TILKO_PRIVATE_AUTH_TYPE'] ?? 'KAKAO').trim();
    return s.isEmpty ? 'KAKAO' : s;
  }

  static bool get isConfigured => apiKey.isNotEmpty;
}
