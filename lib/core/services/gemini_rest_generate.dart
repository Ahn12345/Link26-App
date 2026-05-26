import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/services/gemini_http_exception.dart';

/// [google_generative_ai] 0.4.x 가 최신 모델 ID를 못 찾을 때 REST(v1)로 호출합니다.
abstract final class GeminiRestGenerate {
  static const Duration _timeout = Duration(seconds: 90);

  static String normalizeModelId(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return 'gemini-2.5-flash';
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'-+'), '-');
    if (s.startsWith('models/')) return s.substring(7);
    return s;
  }

  static List<String> visionModelCandidates() {
    final configured = normalizeModelId(GeminiRuntimeConfig.modelId);
    return [
      configured,
      if (configured != 'gemini-2.5-flash') 'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
    ];
  }

  static Future<String?> generateWithImage({
    required String modelId,
    required String prompt,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final key = GeminiRuntimeConfig.apiKey;
    if (key.isEmpty) return null;

    final model = normalizeModelId(modelId);
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
    });

    Object? lastErr;
    for (final apiPrefix in ['v1', 'v1beta']) {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/$apiPrefix/models/'
        '$model:generateContent?key=${Uri.encodeQueryComponent(key)}',
      );
      try {
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(_timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return _textFromResponse(res.body);
        }
        if (kDebugMode) {
          debugPrint(
            'GeminiRestGenerate $apiPrefix/$model HTTP ${res.statusCode}: '
            '${res.body.length > 200 ? res.body.substring(0, 200) : res.body}',
          );
        }
        if (res.statusCode == 403 || res.statusCode == 401) {
          throw GeminiHttpException(res.statusCode, res.body);
        }
        lastErr = GeminiHttpException(res.statusCode, res.body);
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? StateError('Gemini REST failed model=$model');
  }

  static Future<String?> generateText({
    required String modelId,
    required String prompt,
  }) async {
    final key = GeminiRuntimeConfig.apiKey;
    if (key.isEmpty) return null;

    final model = normalizeModelId(modelId);
    final payload = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    Object? lastErr;
    for (final apiPrefix in ['v1', 'v1beta']) {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/$apiPrefix/models/'
        '$model:generateContent?key=${Uri.encodeQueryComponent(key)}',
      );
      try {
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(_timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return _textFromResponse(res.body);
        }
        lastErr = StateError('HTTP ${res.statusCode} $apiPrefix/$model');
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? StateError('Gemini REST failed model=$model');
  }

  static String? _textFromResponse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final first = candidates.first;
      if (first is! Map) return null;
      final content = first['content'];
      if (content is! Map) return null;
      final parts = content['parts'];
      if (parts is! List) return null;
      final buf = StringBuffer();
      for (final p in parts) {
        if (p is! Map) continue;
        final t = p['text'];
        if (t is String && t.isNotEmpty) buf.write(t);
      }
      final out = buf.toString().trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }
}
