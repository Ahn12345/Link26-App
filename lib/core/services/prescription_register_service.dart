import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/services/gemini_rest_generate.dart';
import 'package:link26_app/core/services/prescription_image_prepare.dart';
import 'package:link26_app/core/services/prescription_register_parser.dart';
import 'package:link26_app/features/ai_chat/ai_chat_service.dart';

enum PrescriptionExtractSource { image, pastedText }

class PrescriptionExtractResult {
  const PrescriptionExtractResult({
    required this.names,
    this.source,
    this.errorMessageKo,
  });

  final List<String> names;
  final PrescriptionExtractSource? source;
  final String? errorMessageKo;

  bool get ok => names.isNotEmpty;
}

/// 처방전 사진·텍스트에서 약품명만 추출 (내 복약 목록 등록용, 공단 신고 아님).
abstract final class PrescriptionRegisterService {
  static const Duration _budget = Duration(seconds: 90);

  static const String _imagePrompt = '''
한국 병원 처방전 이미지에서 환자가 복용할 의약품 상품명만 추출하세요.
병원·환자·날짜·용법·IV·수액·검사·바코드는 제외합니다.
응답은 JSON 배열만 출력하세요. 예: ["케피람정100mg","토파맥스정25mg"]
마크다운·설명 문장 없이 배열만.
''';

  static const String _textPrompt = '''
아래는 처방전 OCR 또는 붙여넣기 텍스트입니다.
복용 의약품 상품명만 JSON 배열로 답하세요. 마크다운 없음.

''';

  static String _errorMessageKo(Object error, {String? triedModel}) {
    final s = error.toString();
    if (s.contains('leaked') ||
        s.contains('reported as leaked')) {
      return 'GEMINI_API_KEY가 Google에 의해 차단되었습니다(유출 신고). '
          'AI Studio에서 새 키를 발급해 .env에 넣고 sync_dotenv_asset.ps1 후 앱을 재설치하세요. '
          '기존 키는 Git·채팅에 올리지 마세요.';
    }
    if (s.contains('API_KEY_INVALID') ||
        s.contains('API key not valid') ||
        s.contains('PERMISSION_DENIED') ||
        s.contains('403')) {
      return 'GEMINI_API_KEY가 거부되었습니다. Google AI Studio에서 키를 새로 발급한 뒤 '
          '.env → sync_dotenv_asset.ps1 → 앱 재설치를 해 주세요.';
    }
    if (s.contains('NOT_FOUND') ||
        s.contains('not found') ||
        s.contains('404')) {
      return 'Gemini 모델(${triedModel ?? GeminiRuntimeConfig.modelId})을 찾을 수 없습니다. '
          '.env의 GEMINI_MODEL_ID=gemini-2.5-flash 인지 확인해 주세요.';
    }
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('Network is unreachable')) {
      return '인터넷(Wi‑Fi·데이터) 연결을 확인한 뒤 다시 시도해 주세요.';
    }
    if (s.contains('RESOURCE_EXHAUSTED') || s.contains('429')) {
      return 'Gemini 사용 한도에 걸렸습니다. 잠시 후 다시 시도하거나 직접 입력해 주세요.';
    }
    return '처방전 사진 분석에 실패했습니다. Wi‑Fi·데이터를 확인하거나 '
        '아래에서 약 이름을 직접 입력해 주세요.';
  }

  static Future<String?> _sdkImageJson(Uint8List prepared, String modelId) async {
    final model = GenerativeModel(
      model: modelId,
      apiKey: GeminiRuntimeConfig.apiKey,
    );
    final res = await model
        .generateContent([
          Content.multi([
            TextPart(_imagePrompt),
            DataPart('image/jpeg', prepared),
          ]),
        ])
        .timeout(_budget);
    return res.text?.trim();
  }

  static Future<String?> _generateImageJson(Uint8List prepared) async {
    Object? lastError;
    for (final modelId in GeminiRestGenerate.visionModelCandidates()) {
      // 1) REST v1 — gemini-2.5-flash 등 최신 모델 (권장)
      try {
        final text = await GeminiRestGenerate.generateWithImage(
          modelId: modelId,
          prompt: _imagePrompt,
          imageBytes: prepared,
        );
        if (text != null && text.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('PrescriptionRegister: REST OK model=$modelId');
          }
          return text;
        }
      } catch (e, st) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('PrescriptionRegister: REST $modelId failed: $e\n$st');
        }
      }

      // 2) 레거시 SDK (구 모델용)
      try {
        final text = await _sdkImageJson(prepared, modelId);
        if (text != null && text.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('PrescriptionRegister: SDK OK model=$modelId');
          }
          return text;
        }
      } catch (e, st) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('PrescriptionRegister: SDK $modelId failed: $e\n$st');
        }
      }
    }

    try {
      final chat = AiChatService();
      final body = await chat
          .respondChat(
            '처방전 사진입니다. 복용 약 상품명만 JSON 배열로만 답하세요. '
            '예: ["케피람정100mg"]. 설명·마크다운 없이 배열만.',
            imageBytes: prepared,
            imageMime: 'image/jpeg',
          )
          .timeout(_budget);
      if (body.trim().isNotEmpty) return body;
    } catch (e) {
      lastError ??= e;
    }

    if (lastError != null) throw lastError;
    return null;
  }

  static Future<PrescriptionExtractResult> extractFromImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!GeminiRuntimeConfig.isConfigured) {
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo:
            '처방전 사진 인식에는 GEMINI_API_KEY가 필요합니다. '
            '아래 「약 이름 직접 입력」을 이용해 주세요.',
      );
    }
    try {
      final prepared = PrescriptionImagePrepare.forVisionApi(bytes);
      final text = await _generateImageJson(prepared);
      final names = PrescriptionRegisterParser.parseFromModelText(text ?? '');
      if (names.isEmpty) {
        return PrescriptionExtractResult(
          names: names,
          source: PrescriptionExtractSource.image,
          errorMessageKo: (text == null || text.isEmpty)
              ? '사진에서 약 이름을 찾지 못했습니다. 더 밝게 촬영하거나 직접 입력해 주세요.'
              : '인식 결과를 해석하지 못했습니다. 약 이름을 직접 입력해 주세요.',
        );
      }
      return PrescriptionExtractResult(
        names: names,
        source: PrescriptionExtractSource.image,
      );
    } on TimeoutException {
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo: '처방전 분석 시간이 초과되었습니다. 직접 입력해 주세요.',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PrescriptionRegisterService image: $e\n$st');
      }
      return PrescriptionExtractResult(
        names: [],
        errorMessageKo: _errorMessageKo(e),
      );
    }
  }

  static Future<String?> _generateTextJson(String prompt) async {
    Object? lastError;
    for (final modelId in GeminiRestGenerate.visionModelCandidates()) {
      try {
        final text = await GeminiRestGenerate.generateText(
          modelId: modelId,
          prompt: prompt,
        );
        if (text != null && text.isNotEmpty) return text;
      } catch (e) {
        lastError = e;
      }
      try {
        final model = GenerativeModel(
          model: modelId,
          apiKey: GeminiRuntimeConfig.apiKey,
        );
        final res = await model
            .generateContent([Content.text(prompt)])
            .timeout(_budget);
        final t = res.text?.trim();
        if (t != null && t.isNotEmpty) return t;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  static Future<PrescriptionExtractResult> extractFromPastedText(
    String text,
  ) async {
    final local = PrescriptionRegisterParser.parseFromPastedText(text);
    if (local.length >= 2) {
      return PrescriptionExtractResult(
        names: local,
        source: PrescriptionExtractSource.pastedText,
      );
    }

    if (!GeminiRuntimeConfig.isConfigured) {
      if (local.isNotEmpty) {
        return PrescriptionExtractResult(
          names: local,
          source: PrescriptionExtractSource.pastedText,
        );
      }
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo: '약 이름이 포함된 줄을 한 줄에 하나씩 입력해 주세요.',
      );
    }

    try {
      final raw = await _generateTextJson('$_textPrompt$text');
      final out = PrescriptionRegisterParser.parseFromModelText(raw ?? '');
      if (out.isNotEmpty) {
        return PrescriptionExtractResult(
          names: out,
          source: PrescriptionExtractSource.pastedText,
        );
      }
      if (local.isNotEmpty) {
        return PrescriptionExtractResult(
          names: local,
          source: PrescriptionExtractSource.pastedText,
        );
      }
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo: '텍스트에서 약 이름을 찾지 못했습니다. 약품명 줄만 붙여넣어 주세요.',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PrescriptionRegisterService text: $e\n$st');
      }
      if (local.isNotEmpty) {
        return PrescriptionExtractResult(
          names: local,
          source: PrescriptionExtractSource.pastedText,
        );
      }
      return PrescriptionExtractResult(
        names: [],
        errorMessageKo: _errorMessageKo(e),
      );
    }
  }
}
