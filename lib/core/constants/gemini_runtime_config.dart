import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_keys.dart';

/// Gemini — `.env` 의 `GEMINI_API_KEY` 우선, 없으면 빌드 시 `--dart-define=GEMINI_API_KEY=...`.
abstract final class GeminiRuntimeConfig {
  static String _stripQuotes(String v) {
    var s = v.trim();
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  static String get apiKey {
    final fromEnv = _stripQuotes(dotenv.env['GEMINI_API_KEY'] ?? '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _stripQuotes(ApiConfig.geminiApiKey);
  }

  /// `GEMINI_API_KEY` 가 비어 있지 않으면 true.
  static bool get isConfigured => apiKey.isNotEmpty;

  /// 예: `gemini-2.5-flash` (기본). AI Studio 에서 지원하는 모델 ID 로 변경 가능.
  static String get modelId {
    final v = _stripQuotes(dotenv.env['GEMINI_MODEL_ID'] ?? '');
    if (v.isNotEmpty) return v;
    return 'gemini-2.5-flash';
  }
}
