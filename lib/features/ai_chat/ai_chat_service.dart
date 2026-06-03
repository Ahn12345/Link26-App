import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/network/api_client.dart';
import 'package:link26_app/core/network/api_endpoints.dart';
import 'package:link26_app/features/ai_chat/dur_asset_context.dart';
import 'package:link26_app/features/ai_chat/easy_drug_chat_context.dart';
import 'package:link26_app/features/ai_chat/nhis_chat_context.dart';

import 'ai_chat_models.dart';

/// OCR/채팅: 백엔드 REST가 있으면 우선 사용, 없으면 Gemini·규칙 기반.
class AiChatService {
  AiChatService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  static String get _modelId => GeminiRuntimeConfig.modelId;

  /// NHIS 스냅샷이 느리면 AI 채팅 전체가 멈춘 것처럼 보이므로 상한을 둡니다.
  static const Duration _nhisSnapshotBudget = Duration(seconds: 3);

  /// 멀티모달·긴 프롬프트 대비.
  static const Duration _geminiBudget = Duration(seconds: 120);

  final Dio _dio;

  static bool _restBackendConfigured() {
    var b = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (b.length >= 2 &&
        ((b.startsWith('"') && b.endsWith('"')) ||
            (b.startsWith("'") && b.endsWith("'")))) {
      b = b.substring(1, b.length - 1).trim();
    }
    if (b.isEmpty) return false;
    if (b.toLowerCase().contains('example.com')) return false;
    return true;
  }

  GenerativeModel _geminiModel() => GenerativeModel(
        model: _modelId,
        apiKey: GeminiRuntimeConfig.apiKey,
      );

  Future<String?> _geminiText(String prompt) async {
    final key = GeminiRuntimeConfig.apiKey;
    if (key.isEmpty) return null;
    try {
      debugPrint('Gemini: 텍스트 요청 시작 (길이=${prompt.length})');
      final res = await _geminiModel()
          .generateContent([Content.text(prompt)])
          .timeout(_geminiBudget);
      debugPrint('Gemini: 텍스트 응답 성공');
      return res.text?.trim();
    } on TimeoutException {
      debugPrint('Gemini: 텍스트 타임아웃');
      if (kDebugMode) debugPrint('Gemini generateContent timeout');
      return null;
    } catch (e, st) {
      debugPrint('Gemini: 텍스트 실패 $e');
      if (kDebugMode) {
        debugPrint('Gemini generateContent failed: $e\n$st');
      }
      return null;
    }
  }

  Future<String?> _geminiFromContents(List<Content> contents) async {
    if (GeminiRuntimeConfig.apiKey.isEmpty) {
      debugPrint('Gemini: API 키 없음 — 멀티모달 스킵');
      return null;
    }
    try {
      debugPrint('Gemini: 멀티모달 요청 시작 — contents=${contents.length}');
      final res =
          await _geminiModel().generateContent(contents).timeout(_geminiBudget);
      debugPrint('Gemini: 멀티모달 응답 성공 — text=${res.text?.length ?? 0}자');
      return res.text?.trim();
    } on TimeoutException {
      debugPrint('Gemini: 멀티모달 타임아웃');
      if (kDebugMode) debugPrint('Gemini multimodal timeout');
      return null;
    } catch (e, st) {
      debugPrint('Gemini: 멀티모달 실패 $e');
      if (kDebugMode) {
        debugPrint('Gemini multimodal failed: $e\n$st');
      }
      return null;
    }
  }

  /// 약·처방·이미지 문의는 DUR+NHIS+2단계 Gemini. 그 외는 일상 대화.
  static bool shouldRunMedicinePipeline(String text, {required bool hasImage}) {
    if (hasImage) return true;
    final t = text.trim();
    if (t.length < 2) return false;
    const hints = [
      '약', '처방', '영양제', '먹어', '복용', '금기', '상호작용', 'dur',
      '건보', '공단', '처방전', '병용', '부작용', '투약', 'tablet', 'capsule',
      'mg', 'ml', '정', '캡슐', '물약', '항생', '진통', '감기',
    ];
    final low = t.toLowerCase();
    for (final h in hints) {
      if (t.contains(h) || low.contains(h.toLowerCase())) return true;
    }
    if (RegExp(r'^(hi|hello|hey|thanks|thank you|ok|bye|good morning)\b',
            caseSensitive: false)
        .hasMatch(low)) {
      return false;
    }
    if (RegExp(r'[A-Za-z]{7,}').hasMatch(t)) return true;
    if (t.length >= 26) return true;
    return false;
  }

  /// 텍스트 ± 이미지. 약 관련이면 1차(텍스트+이미지+DUR+NHIS) → 2차(신호등 고정 문구 + NHIS 재조회).
  Future<String> respondChat(
    String userText, {
    Uint8List? imageBytes,
    String? imageMime,
  }) async {
    final text = userText.trim();
    final hasImg = imageBytes != null && imageBytes.isNotEmpty;
    debugPrint('Gemini: respondChat 호출 — text="${text.isEmpty ? "(없음)" : text}" hasImg=$hasImg imageBytes=${imageBytes?.length ?? 0}');
    if (!shouldRunMedicinePipeline(text, hasImage: hasImg)) {
      debugPrint('Gemini: 일상 대화 파이프라인 선택');
      return _respondCasual(text.isEmpty ? '…' : text);
    }
    debugPrint('Gemini: 약 2단계 파이프라인 선택');
    return _respondMedicineTwoPass(text, imageBytes, imageMime);
  }

  Future<String> _respondCasual(String userText) async {
    final key = GeminiRuntimeConfig.apiKey;
    if (key.isEmpty) {
      return '일상 대화도 Gemini를 쓰려면 `.env`에 GEMINI_API_KEY를 넣어 주세요.';
    }
    final p =
        '(역할) 건강·복약 앱의 AI. 한국어로 짧고 자연스럽게.\n'
        '(금지) 의학적 진단·처방·특정 약 용량 지시. 필요하면 의사·약사 상담을 권하세요.\n'
        '(사용자) $userText';
    return (await _geminiText(p)) ?? '응답을 만들지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }

  Future<String> _respondMedicineTwoPass(
    String userText,
    Uint8List? imageBytes,
    String? imageMime,
  ) async {
    final key = GeminiRuntimeConfig.apiKey;
    final durQuery = userText.isEmpty ? '의약품' : userText;
    debugPrint('Gemini: 2단계 시작 — key길이=${key.length} imageBytes=${imageBytes?.length ?? 0} mime=$imageMime');

    String durCtx = '(DUR 스킵)';
    String nhisA = '(NHIS 스킵)';
    String cacheNames = '(캐시 스킵)';
    String easyDrugA = '(e약은요 스킵)';
    try {
      debugPrint('Gemini: 컨텍스트 수집 시작');
      final results = await Future.wait<String>([
        DurAssetContext.buildSnippetForQuery(durQuery)
            .timeout(const Duration(seconds: 5), onTimeout: () => '(DUR 로딩 타임아웃)'),
        NhisChatContext.fetchMedicationsSnapshot(timeLimit: _nhisSnapshotBudget),
        NhisChatContext.cachedMedicineNamesSummary()
            .timeout(const Duration(seconds: 3), onTimeout: () => '(캐시 타임아웃)'),
        EasyDrugChatContext.buildSnippetForUserText(userText)
            .timeout(const Duration(seconds: 5), onTimeout: () => '(e약은요 타임아웃)'),
      ]);
      durCtx = results[0];
      nhisA = results[1];
      cacheNames = results[2];
      easyDrugA = results[3];
      debugPrint('Gemini: 컨텍스트 수집 완료');
    } catch (e, st) {
      debugPrint('Gemini: 컨텍스트 수집 오류 $e');
      debugPrint('$st');
    }

    if (key.isEmpty) {
      return '🟡 권고 —\n'
          'Gemini 분석을 쓰려면 GEMINI_API_KEY가 필요합니다.\n\n'
          '[DUR 발췌]\n$durCtx\n\n'
          '[건강보험 복약 스냅샷]\n$nhisA\n\n'
          '[로컬 복약 이름]\n$cacheNames\n\n'
          '[식약처 e약은요·공공데이터 발췌]\n$easyDrugA';
    }

    final primaryIntro = '''
[1차 분석 — 출력은 JSON 한 덩어리만, 코드펜스·마크다운 금지]
역할: 약국 보조 AI. 의학적 진단·처방 금지.
사용자_텍스트: ${userText.isEmpty ? "(없음, 이미지만 가능)" : userText}

[CONTEXT: DUR CSV 일부 — 병용금기·노인주의]
$durCtx

[CONTEXT: 국민건강보험 복약 API·캐시 스냅샷 JSON 또는 메시지]
$nhisA

[CONTEXT: 로컬에 저장된 복약 이름 요약]
$cacheNames

[CONTEXT: 식약처 e약은요(공공데이터) — 약 검색·효능·용법 참고. 이미지만 있을 때는 추정 약명을 names_guessed에 넣으세요]
$easyDrugA

JSON 형식만 출력:
{"draft_signal":"green|yellow|red","draft_reason":"한글 2문장 이내","dur_note":"한글","nhis_note":"한글","names_guessed":["추정한_약_이름"]}

의미: green=현재 자료 기준 특별한 병용·금기 징후가 약함, yellow=주의·확인·전문가 상담 필요, red=병용금기·중대 위험 가능성이 높음.
names_guessed: 사용자 문장·이미지에서 추정한 의약품 이름(한글 상품명 위주, 없으면 []).
''';

    final List<Content> primaryCall;
    if (imageBytes != null &&
        imageMime != null &&
        imageMime.isNotEmpty &&
        imageBytes.isNotEmpty) {
      debugPrint('Gemini: 이미지 포함 멀티모달 호출 준비 — mime=$imageMime bytes=${imageBytes.length}');
      primaryCall = [
        Content.multi([
          TextPart(primaryIntro),
          DataPart(imageMime, imageBytes),
        ]),
      ];
    } else {
      debugPrint('Gemini: 텍스트 전용 호출 준비');
      primaryCall = [Content.text(primaryIntro)];
    }

    var primaryRaw = await _geminiFromContents(primaryCall);
    debugPrint('Gemini: 1차 결과 = ${primaryRaw == null ? "null" : "${primaryRaw.length}자"}');
    primaryRaw ??= await _geminiText(primaryIntro);
    if (primaryRaw == null || primaryRaw.trim().isEmpty) {
      return '🟡 권고 —\n1차 분석을 생성하지 못했습니다. 네트워크·API 키·모델명을 확인해 주세요.';
    }

    final nhisB = await NhisChatContext.fetchMedicationsSnapshot(
      timeLimit: _nhisSnapshotBudget,
    );

    final guessedNames =
        EasyDrugChatContext.parseNamesGuessedFromPrimaryJson(primaryRaw);
    final easyDrugB =
        await EasyDrugChatContext.buildSnippetForNames(guessedNames);

    final secondPrompt = '''
[2차 최종 검토 — 출력 형식 엄수]
첫 줄은 반드시 아래 중 하나로 **시작** (공백·이모지 동일):
🟢 먹어도 괜찮아 —
🟡 권고 —
🔴 절대 먹으면 안 돼 —

같은 줄에 한 문장을 이어 쓰고, 다음 줄부터 한글 2~4문장만 추가하세요.
의학적 진단·처방·특정 용량 지시 금지. 반드시 의사·약사 상담을 안내하세요.

[1차 결과]
$primaryRaw

[DUR 발췌 재참조]
$durCtx

[NHIS 복약 API 1차 스냅샷]
$nhisA

[NHIS 복약 API 2차 재조회 스냅샷 — 1차와 다르면 더 최신·보수적으로 판단]
$nhisB

${easyDrugB.isEmpty ? '' : '[e약은요·1차 추정 약명 기준 보강]\n$easyDrugB\n'}

불확실하면 🟡, 위험 징후가 있으면 🔴를 선택하세요.
''';

    var finalText = await _geminiText(secondPrompt);
    debugPrint('Gemini: 2차 결과 = ${finalText == null ? "null" : "${finalText.length}자"}');
    finalText = _ensureTrafficLightFormat(finalText, primaryRaw);
    return finalText;
  }

  String _ensureTrafficLightFormat(String? second, String primaryFallback) {
    var t = (second ?? '').trim();
    if (t.startsWith('🟢') || t.startsWith('🟡') || t.startsWith('🔴')) {
      return t;
    }
    final sig = _signalFromDraftJson(primaryFallback);
    final prefix = switch (sig) {
      SafetySignal.green => '🟢 먹어도 괜찮아 —',
      SafetySignal.yellow => '🟡 권고 —',
      SafetySignal.red => '🔴 절대 먹으면 안 돼 —',
    };
    if (t.isEmpty) t = '(2차 검토 문구 생성 실패. 1차 요약을 참고하세요.)';
    return '$prefix\n$t\n\n[1차 요약]\n$primaryFallback';
  }

  SafetySignal _signalFromDraftJson(String raw) {
    final u = raw.toLowerCase();
    if (u.contains('"draft_signal":"red') ||
        u.contains('"draft_signal": "red') ||
        u.contains('draft_signal":"red')) {
      return SafetySignal.red;
    }
    if (u.contains('"draft_signal":"yellow') ||
        u.contains('"draft_signal": "yellow')) {
      return SafetySignal.yellow;
    }
    if (u.contains('"draft_signal":"green') ||
        u.contains('"draft_signal": "green')) {
      return SafetySignal.green;
    }
    return _signalFromText(raw);
  }

  /// 처방전·약 라벨 **이미지** — [respondChat]과 동일 파이프라인.
  Future<MedicineInsight> analyzeMedicineImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final body = await respondChat('', imageBytes: bytes, imageMime: mimeType);
    return MedicineInsight(
      productName: '분석 결과',
      signal: _signalFromText(body),
      recommendation: body,
      reason: '',
    );
  }

  /// [MedicineInsight] 를 채팅 말풍선용 단일 문자열로.
  static String insightToChatBody(MedicineInsight i) {
    final emoji = switch (i.signal) {
      SafetySignal.green => '🟢',
      SafetySignal.yellow => '🟡',
      SafetySignal.red => '🔴',
    };
    final buf = StringBuffer()
      ..writeln('$emoji ${i.productName}')
      ..writeln()
      ..writeln(i.recommendation)
      ..writeln()
      ..write(i.reason);
    if (i.secondaryReview != null && i.secondaryReview!.trim().isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..write(i.secondaryReview);
    }
    return buf.toString().trim();
  }

  static const String _geminiFailureHintKo =
      'Gemini 응답을 받지 못했습니다. Google AI Studio에서 발급한 키를 프로젝트 루트 `.env`의 '
      'GEMINI_API_KEY에 넣고, `pubspec.yaml`에 `.env`가 assets로 포함돼 있는지 확인한 뒤 앱을 '
      '완전히 다시 실행(재빌드)하세요. 모델 ID(GEMINI_MODEL_ID)도 AI Studio에서 쓰는 이름과 맞추세요.';

  /// REST `POST /ai/chat` — 백엔드가 없거나 실패 시 [respondChat](일상/약 2단계·DUR·NHIS).
  Future<String> sendChatMessage(String message) async {
    if (!_restBackendConfigured()) {
      return respondChat(message);
    }
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.aiChat,
        data: {'message': message},
      );
      final data = response.data;
      if (data is Map) {
        return '${data['answer'] ?? data['message'] ?? data['text'] ?? ''}'.trim();
      }
      return '$data';
    } on DioException {
      return respondChat(message);
    }
  }

  Future<MedicineInsight> analyzePrescriptionImage({
    required String recognizedText,
  }) async {
    try {
      final endpoint = dotenv.env['AI_API_URL']?.trim().isNotEmpty == true
          ? dotenv.env['AI_API_URL']!.trim()
          : ApiEndpoints.aiPrescription;
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {'recognizedText': recognizedText},
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      return MedicineInsight(
        productName:
            '${data['productName'] ?? data['medicineName'] ?? '분석된 약'}',
        signal: _parseSignal('${data['signal'] ?? 'green'}'),
        recommendation:
            '${data['recommendation'] ?? '처방 안내에 따라 복용하세요.'}',
        reason: '${data['reason'] ?? '서버 분석 결과입니다.'}',
      );
    } on DioException {
      // REST 없거나 오류 → Gemini / 규칙
    }

    final key = GeminiRuntimeConfig.apiKey;
    if (key.isNotEmpty) {
      final p1 =
          'You are a cautious pharmacy assistant. Given OCR text from a label or prescription, '
          'reply in 4 lines: (1) product guess (2) GREEN/YELLOW/RED signal (3) one-sentence recommendation '
          '(4) short reason. OCR:\n$recognizedText';
      final first = await _geminiText(p1);
      if (first != null && first.isNotEmpty) {
        final p2 =
            'Double-check the previous draft for patient safety. If anything is uncertain, say VERIFY_WARN. '
            'Otherwise say VERIFY_OK. Then add one short sentence. Draft:\n$first';
        final second = await _geminiText(p2);
        return MedicineInsight(
          productName: GeminiRuntimeConfig.modelId,
          signal: _signalFromText('$first $second'),
          recommendation: first,
          reason: 'Primary model output (not medical advice).',
          secondaryReview: second,
        );
      }
    }
    return _ruleBasedInsight(recognizedText);
  }

  SafetySignal _signalFromText(String t) {
    final u = t.toUpperCase();
    if (u.contains('RED') || u.contains('VERIFY_WARN')) {
      return SafetySignal.red;
    }
    if (u.contains('YELLOW') || u.contains('ORANGE')) {
      return SafetySignal.yellow;
    }
    return SafetySignal.green;
  }

  MedicineInsight _ruleBasedInsight(String recognizedText) {
    final normalized = recognizedText.toLowerCase();
    if (normalized.contains('warfarin') || normalized.contains('bleeding')) {
      return const MedicineInsight(
        productName: 'Detected medication',
        signal: SafetySignal.red,
        recommendation:
            'Do not take now. Contact your clinician immediately.',
        reason: 'Potential severe interaction or bleeding risk keywords found.',
      );
    }
    if (normalized.contains('caffeine') || normalized.contains('insomnia')) {
      return const MedicineInsight(
        productName: 'Detected supplement',
        signal: SafetySignal.yellow,
        recommendation: 'Take with caution and avoid late-night intake.',
        reason: 'Sleep-impacting keyword detected from supplement text.',
      );
    }
    return const MedicineInsight(
      productName: 'Detected medicine/supplement',
      signal: SafetySignal.green,
      recommendation:
          'Looks generally acceptable. Follow prescription timing.',
      reason: 'No high-risk keyword found in this preliminary pass.',
    );
  }

  Future<ChatTriageResult> triageMessage(String message) async {
    final key = GeminiRuntimeConfig.apiKey;
    if (key.isNotEmpty) {
      final p1 =
          'Triage user message for urgency (not a diagnosis). Reply: URGENT_YES or URGENT_NO, '
          'then one short primary answer in Korean or English, then one follow-up question.\n$message';
      final first = await _geminiText(p1);
      if (first != null && first.isNotEmpty) {
        final p2 =
            'Review this triage draft. Confirm or correct urgency. Keep very brief.\n$first';
        final second = await _geminiText(p2);
        final urgent = first.toUpperCase().contains('URGENT_YES') ||
            (second?.toUpperCase().contains('URGENT_YES') ?? false);
        final lines = first.split('\n');
        final primary = lines.length > 1 ? lines.sublist(1).join('\n') : first;
        return ChatTriageResult(
          urgent: urgent,
          primaryAnswer: primary,
          followUpPrompt:
              'Please share more detail if symptoms change. Not a substitute for ER care.',
          secondaryReview: second,
        );
      }
      return ChatTriageResult(
        urgent: false,
        primaryAnswer: _geminiFailureHintKo,
        followUpPrompt:
            '키·네트워크·모델명을 확인한 뒤 다시 질문해 보세요. 응급 증상이면 119·응급실로 연락하세요.',
      );
    }
    return Future.value(_ruleBasedTriage(message));
  }

  ChatTriageResult _ruleBasedTriage(String message) {
    final lower = message.toLowerCase();
    final urgentKeywords = [
      'chest pain',
      'difficulty breathing',
      'faint',
      'seizure',
      'severe bleeding',
      '흉통',
      '호흡곤란',
      '실신',
      '발작',
      '심한출혈',
    ];
    final urgent = urgentKeywords.any(lower.contains);
    if (urgent) {
      return const ChatTriageResult(
        urgent: true,
        primaryAnswer:
            'Emergency symptoms detected. Call 119 or go to ER now.',
        followUpPrompt: 'Share medicines taken and symptom start time.',
      );
    }
    return const ChatTriageResult(
      urgent: false,
      primaryAnswer:
          'No immediate red-flag symptom detected in this message.',
      followUpPrompt:
          'Please share current symptoms and latest medication time.',
    );
  }

  SafetySignal _parseSignal(String value) {
    switch (value.toLowerCase()) {
      case 'red':
      case 'danger':
        return SafetySignal.red;
      case 'yellow':
      case 'warning':
        return SafetySignal.yellow;
      default:
        return SafetySignal.green;
    }
  }
}