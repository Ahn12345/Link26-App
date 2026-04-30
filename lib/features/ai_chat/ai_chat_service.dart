import 'ai_chat_models.dart';

/// AI ì±„íŒ…/?´ë?ì§€ ?¸ì‹ ë°±ì—”???°ë™ ???¨ê³„??ê·œì¹™ ê¸°ë°˜ ?¤í….
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

  /// ?„í”ˆ ?í™© ?˜ì‹¬ ??"ê¶Œê³ "ë³´ë‹¤ ?°ì„ ?´ì„œ ëª…í™•??1ì°??µì„ ì¤€??
  ChatTriageResult triageMessage(String message) {
    final lower = message.toLowerCase();
    final urgentKeywords = [
      'chest pain',
      'difficulty breathing',
      'faint',
      'seizure',
      'severe bleeding',
      '?¸í¡ê³¤ë?',
      'ê°€???µì¦',
      '?¤ì‹ ',
      'ê²½ë ¨',
      '?¼ê? ë©ˆì¶”ì§€',
    ];
    final urgent = urgentKeywords.any(lower.contains);
    if (urgent) {
      return const ChatTriageResult(
        urgent: true,
        primaryAnswer:
            '?‘ê¸‰ ?˜ì‹¬ ?íƒœ?…ë‹ˆ?? ì§€ê¸?ì¦‰ì‹œ 119 ?ëŠ” ?‘ê¸‰?¤ë¡œ ?´ë™?˜ì„¸??',
        followUpPrompt: 'ë³µìš©?????ì–‘?œì? ì¦ìƒ ?œì‘ ?œê°„???Œë ¤ì£¼ì„¸??',
      );
    }
    return const ChatTriageResult(
      urgent: false,
      primaryAnswer: '?‘ê¸‰ ? í˜¸????•„ ë³´ì…?ˆë‹¤. ì¦ìƒ??ë§ëŠ” ë³µìš© ?œê°„???ˆë‚´? ê²Œ??',
      followUpPrompt: '?„ì¬ ì¦ìƒ, ë³µìš© ì¤‘ì¸ ?? ë§ˆì?ë§?ë³µìš© ?œê°„???…ë ¥?´ì£¼?¸ìš”.',
    );
  }
}
