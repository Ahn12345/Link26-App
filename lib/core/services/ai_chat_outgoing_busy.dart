import 'package:flutter/foundation.dart';

/// AI 채팅 전송·분석 중 — 다른 탭으로 나가도 true 가 유지되어 복귀 시 로딩 상태를 이어갑니다.
final class AiChatOutgoingBusy extends ValueNotifier<bool> {
  AiChatOutgoingBusy._() : super(false);
  static final AiChatOutgoingBusy instance = AiChatOutgoingBusy._();
}
