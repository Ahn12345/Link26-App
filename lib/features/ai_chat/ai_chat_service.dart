import 'ai_chat_models.dart';

/// AI 채팅/이미지 인식 백엔드 연동 전 단계의 규칙 기반 스텁.
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

  /// 아픈 상황 의심 시 "권고"보다 우선해서 명확한 1차 답을 준다.
  ChatTriageResult triageMessage(String message) {
    final lower = message.toLowerCase();
    final urgentKeywords = [
      'chest pain',
      'difficulty breathing',
      'faint',
      'seizure',
      'severe bleeding',
      '호흡곤란',
      '가슴 통증',
      '실신',
      '경련',
      '피가 멈추지',
    ];
    final urgent = urgentKeywords.any(lower.contains);
    if (urgent) {
      return const ChatTriageResult(
        urgent: true,
        primaryAnswer:
            '응급 의심 상태입니다. 지금 즉시 119 또는 응급실로 이동하세요.',
        followUpPrompt: '복용한 약/영양제와 증상 시작 시간을 알려주세요.',
      );
    }
    return const ChatTriageResult(
      urgent: false,
      primaryAnswer: '응급 신호는 낮아 보입니다. 증상에 맞는 복용 시간을 안내할게요.',
      followUpPrompt: '현재 증상, 복용 중인 약, 마지막 복용 시간을 입력해주세요.',
    );
  }
}
