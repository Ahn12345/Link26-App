import 'package:flutter/foundation.dart';

import 'package:link26_app/core/services/ai_chat_local_store.dart';
import 'package:link26_app/models/link_models.dart';

/// 탭 전환으로 [AiChatScreen] 이 dispose 되어도 대화·일일 사용 횟수를 메모리에 유지합니다.
/// 말풍선은 [AiChatLocalStore] → SQLite(`link26_ai_chat.db`)에 저장되어 앱 재시작 후에도 복원됩니다.
abstract final class AiChatConversationCache {
  AiChatConversationCache._();

  static final List<ChatMessage> messages = <ChatMessage>[];

  static int dailyUsed = 0;

  /// 말풍선 목록이 바뀌면 증가 — 탭 밖에서 [persist]만 호출돼도 AI 탭이 다시 그려집니다.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool _hydratedMessages = false;

  /// 매 진입마다 일일 한도는 디스크와 맞추고, 말풍선은 최초 1회만 디스크에서 채웁니다.
  static Future<void> ensureReady() async {
    dailyUsed = await AiChatLocalStore.loadDailyUsed();
    if (_hydratedMessages) return;
    messages
      ..clear()
      ..addAll(await AiChatLocalStore.loadMessages());
    _hydratedMessages = true;
  }

  static Future<void> persist() async {
    await AiChatLocalStore.saveDailyUsed(dailyUsed);
    await AiChatLocalStore.saveMessages(messages);
    revision.value = revision.value + 1;
  }

  /// 테스트·로그아웃 등 — 메모리·디스크 대화를 비웁니다.
  static Future<void> resetSession() async {
    _hydratedMessages = false;
    messages.clear();
    dailyUsed = 0;
    revision.value = revision.value + 1;
    await AiChatLocalStore.clearMessages();
  }
}
