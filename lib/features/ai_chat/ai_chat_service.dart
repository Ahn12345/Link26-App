import 'ai_chat_models.dart';

/// Rule-based demo service until backend AI is connected.
class AiChatService {
  Future<MedicineInsight> analyzePrescriptionImage({
    required String recognizedText,
  }) async {
    final normalized = recognizedText.toLowerCase();
    if (normalized.contains('warfarin') || normalized.contains('bleeding')) {
      return const MedicineInsight(
        productName: 'Detected medication',
        signal: SafetySignal.red,
        recommendation: 'Do not take now. Contact your clinician immediately.',
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
      recommendation: 'Looks generally acceptable. Follow prescription timing.',
      reason: 'No high-risk keyword found in this preliminary pass.',
    );
  }

  ChatTriageResult triageMessage(String message) {
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
        primaryAnswer: 'Emergency symptoms detected. Call 119 or go to ER now.',
        followUpPrompt: 'Share medicines taken and symptom start time.',
      );
    }
    return const ChatTriageResult(
      urgent: false,
      primaryAnswer: 'No immediate red-flag symptom detected in this message.',
      followUpPrompt: 'Please share current symptoms and latest medication time.',
    );
  }
}