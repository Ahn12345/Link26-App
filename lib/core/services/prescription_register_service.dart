import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/services/prescription_register_parser.dart';

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

  static Future<PrescriptionExtractResult> extractFromImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!GeminiRuntimeConfig.isConfigured) {
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo:
            '처방전 사진 인식에는 GEMINI_API_KEY가 필요합니다. '
            '또는 처방 내용을 텍스트로 붙여넣어 주세요.',
      );
    }
    try {
      final model = GenerativeModel(
        model: GeminiRuntimeConfig.modelId,
        apiKey: GeminiRuntimeConfig.apiKey,
      );
      final res = await model
          .generateContent([
            Content.multi([
              TextPart(_imagePrompt),
              DataPart(mimeType, bytes),
            ]),
          ])
          .timeout(_budget);
      final text = res.text?.trim() ?? '';
      final names = PrescriptionRegisterParser.parseFromModelText(text);
      if (names.isEmpty) {
        return PrescriptionExtractResult(
          names: names,
          source: PrescriptionExtractSource.image,
          errorMessageKo: text.isEmpty
              ? '사진에서 약 이름을 찾지 못했습니다. 더 밝게·약 이름이 보이게 다시 촬영하거나 텍스트로 붙여넣어 주세요.'
              : '인식 결과를 해석하지 못했습니다. 텍스트 붙여넣기를 이용해 주세요.',
        );
      }
      return PrescriptionExtractResult(
        names: names,
        source: PrescriptionExtractSource.image,
      );
    } on TimeoutException {
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo: '처방전 분석 시간이 초과되었습니다. 다시 시도하거나 텍스트로 붙여넣어 주세요.',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PrescriptionRegisterService image: $e\n$st');
      }
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo: '처방전 사진 분석에 실패했습니다. 네트워크·API 키를 확인하거나 텍스트로 붙여넣어 주세요.',
      );
    }
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
      final model = GenerativeModel(
        model: GeminiRuntimeConfig.modelId,
        apiKey: GeminiRuntimeConfig.apiKey,
      );
      final res = await model
          .generateContent([
            Content.text('$_textPrompt$text'),
          ])
          .timeout(_budget);
      final out = PrescriptionRegisterParser.parseFromModelText(
        res.text?.trim() ?? '',
      );
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
      return const PrescriptionExtractResult(
        names: [],
        errorMessageKo: '텍스트 분석에 실패했습니다. 약품명을 한 줄에 하나씩 입력해 주세요.',
      );
    }
  }
}
