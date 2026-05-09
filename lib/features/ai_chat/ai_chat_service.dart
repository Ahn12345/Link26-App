import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:link26_app/core/constants/api_keys.dart';

import 'ai_chat_models.dart';

/// OCR/?? ??: API ?? ??? Gemini 2.5 Flash 2??, ??? ?? ?? ??.
class AiChatService {
  static const _modelId = 'gemini-2.5-flash';

  Future<String?> _geminiText(String prompt) async {
    final key = ApiConfig.geminiApiKey.trim();
    if (key.isEmpty) return null;
    final model = GenerativeModel(model: _modelId, apiKey: key);
    final res = await model.generateContent([Content.text(prompt)]);
    return res.text?.trim();
  }

  Future<MedicineInsight> analyzePrescriptionImage({
    required String recognizedText,
  }) async {
    final key = ApiConfig.geminiApiKey.trim();
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
          productName: 'Gemini 2.5 Flash',
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
    final key = ApiConfig.geminiApiKey.trim();
    if (key.isNotEmpty) {
      final p1 =
          'Triage user message for urgency (not a diagnosis). Reply: URGENT_YES or URGENT_NO, '
          'then one short primary answer in Korean or English, then one follow-up question.\n$message';
      final first = await _geminiText(p1);
      if (first != null && first.isNotEmpty) {
        final p2 =
            'Review this triage draft. Confirm or correct urgency. Keep very brief.\n$first';
        final second = await _geminiText(p2);
        final urgent =
            first.toUpperCase().contains('URGENT_YES') ||
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
}
