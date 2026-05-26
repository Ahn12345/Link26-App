import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:link26_app/core/constants/gemini_runtime_config.dart';

/// Google AI Studio 키가 동작하는지 빠르게 확인합니다.
abstract final class GeminiApiKeyStatus {
  static const Duration _timeout = Duration(seconds: 12);

  /// null 이면 정상. 문자열이면 사용자에게 보여 줄 한국어 안내.
  static Future<String?> checkBlockingIssueKo() async {
    if (!GeminiRuntimeConfig.isConfigured) {
      return 'GEMINI_API_KEY가 비어 있습니다. 루트 .env에 키를 넣고 '
          'sync_dotenv_asset.ps1 후 앱을 재설치하세요.';
    }

    final key = GeminiRuntimeConfig.apiKey;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models'
      '?key=${Uri.encodeQueryComponent(key)}',
    );

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      return messageFromHttp(res.statusCode, res.body);
    } catch (e) {
      return 'Gemini 서버에 연결하지 못했습니다. Wi‑Fi·데이터를 확인해 주세요. ($e)';
    }
  }

  static String messageFromHttp(int status, String body) {
    final lower = body.toLowerCase();
    if (lower.contains('leaked') || lower.contains('reported as leaked')) {
      return '이 GEMINI_API_KEY는 Google에서 유출 키로 차단했습니다. '
          'AI Studio에서 새 키를 발급해 .env만 바꾼 뒤 sync_dotenv_asset.ps1 · 재설치하세요. '
          '(모델 이름 문제가 아닙니다.)';
    }
    if (status == 403 || lower.contains('permission_denied')) {
      return 'GEMINI_API_KEY가 거부되었습니다(403). '
          'AI Studio에서 키를 새로 발급해 주세요.';
    }
    if (status == 404) {
      return 'Gemini API 주소를 찾을 수 없습니다. 앱을 최신 빌드로 재설치해 주세요.';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map) {
          final msg = err['message'];
          if (msg is String && msg.isNotEmpty) {
            return 'Gemini: $msg';
          }
        }
      }
    } catch (_) {}
    return 'Gemini API 오류(HTTP $status). 키·네트워크를 확인해 주세요.';
  }
}
