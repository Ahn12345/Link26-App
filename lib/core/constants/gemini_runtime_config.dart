import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_keys.dart';

/// Gemini — `.env` 의 `GEMINI_API_KEY` 우선, 없으면 빌드 시 `--dart-define=GEMINI_API_KEY=...`.
abstract final class GeminiRuntimeConfig {
  static String get apiKey {
    final v = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (v.isNotEmpty) return v;
    return ApiConfig.geminiApiKey.trim();
  }

  /// 예: `gemini-2.5-flash` (기본). AI Studio 에서 지원하는 모델 ID 로 변경 가능.
  static String get modelId {
    final v = dotenv.env['GEMINI_MODEL_ID']?.trim() ?? '';
    if (v.isNotEmpty) return v;
    return 'gemini-2.5-flash';
  }
}
