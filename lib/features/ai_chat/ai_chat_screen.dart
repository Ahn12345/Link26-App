import 'package:flutter/material.dart';

import 'package:link26_app/core/services/ai_chat_session_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/models/link_models.dart';

/// 시안 기준 AI 약 정보 채팅 (`#3B6CF5` 등).
///
/// [embeddedInShell]: 하단 탭일 때 뒤로가기 없음.
class AiChatScreen extends StatelessWidget {
  const AiChatScreen({
    super.key,
    this.showScaffold = true,
    this.embeddedInShell = false,
    /// 하단 탭에서 다른 탭 → AI 로 전환될 때마다 증가시키면 첫 말풍선 접속 시각이 갱신됩니다.
    this.visitStamp = 0,
  });

  static const routeName = '/ai-chat';

  final bool showScaffold;
  final bool embeddedInShell;

  /// [embeddedInShell] 일 때만 사용. 라우트 단독 진입은 0 그대로 두면 됩니다.
  final int visitStamp;

  @override
  Widget build(BuildContext context) {
    final body = _AiChatBody(
      embeddedInShell: embeddedInShell,
      visitStamp: visitStamp,
    );
    if (!showScaffold) {
      return ColoredBox(color: Link26Surface.scaffoldBg, child: body);
    }
    return Scaffold(
      backgroundColor: Link26Surface.scaffoldBg,
      body: body,
    );
  }
}

class _AiChatBody extends StatefulWidget {
  const _AiChatBody({
    required this.embeddedInShell,
    required this.visitStamp,
  });

  final bool embeddedInShell;
  final int visitStamp;

  @override
  State<_AiChatBody> createState() => _AiChatBodyState();
}

class _AiChatBodyState extends State<_AiChatBody> {
  final controller = TextEditingController();

  /// 사용자 전송 이후 말풍선만 (첫 AI 인사는 [_AiWelcomeBubble] 고정).
  final List<ChatMessage> messages = [];

  /// 첫 말풍선 하단 시각 — [AiChatSessionStore.touchAccess] 로 저장되는 접속 시각과 동일.
  String? _welcomeAccessLabel;

  static const int _dailyLimit = 10;
  int _dailyUsed = 3;

  @override
  void initState() {
    super.initState();
    if (!widget.embeddedInShell) {
      _refreshWelcomeAccess();
    }
  }

  @override
  void didUpdateWidget(covariant _AiChatBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.embeddedInShell &&
        widget.visitStamp > 0 &&
        widget.visitStamp != oldWidget.visitStamp) {
      _refreshWelcomeAccess();
    }
  }

  Future<void> _refreshWelcomeAccess() async {
    final at = await AiChatSessionStore.touchAccess();
    if (!mounted) return;
    setState(() {
      _welcomeAccessLabel = AiChatSessionStore.formatAccessLabel(at);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(ChatMessage(isUser: true, time: _nowLabel(), text: text));
      messages.add(
        ChatMessage(
          isUser: false,
          time: _nowLabel(),
          text:
              '말씀해 주신 내용을 반영했습니다. 실제 서비스에서는 약학 DB·API와 연동해 답변합니다.',
        ),
      );
      if (_dailyUsed < _dailyLimit) _dailyUsed++;
    });
    controller.clear();
  }

  void openCamera() {
    setState(() {
      messages.add(
        ChatMessage(
          isUser: true,
          time: _nowLabel(),
          text: '사진을 선택했습니다.',
        ),
      );
      messages.add(
        ChatMessage(
          isUser: false,
          time: _nowLabel(),
          text: '이미지 분석은 image_picker·업로드 API 연결 후 표시됩니다.',
        ),
      );
      if (_dailyUsed < _dailyLimit) _dailyUsed++;
    });
  }

  String _nowLabel() =>
      AiChatSessionStore.formatAccessLabel(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final embedded = widget.embeddedInShell;
    final shellNavPad =
        embedded ? MediaQuery.of(context).padding.bottom + 88.0 : 0.0;

    return SafeArea(
      bottom: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: shellNavPad),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChatHeader(
                used: _dailyUsed,
                limit: _dailyLimit,
                embedded: embedded,
              ),
              Expanded(
                child: ColoredBox(
                  color: Link26Surface.scaffoldBg,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _AiWelcomeBubble(
                        timeLabel: _welcomeAccessLabel ?? '…',
                      ),
                      ...messages.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _ChatBubble(message: m),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _DisclaimerBanner(),
              _InputBar(
                controller: controller,
                onSend: sendMessage,
                onCamera: openCamera,
              ),
            ],
          ),
          ),
          if (!embedded)
            Positioned(
              top: 4,
              left: 0,
              child: IconButton(
                style: IconButton.styleFrom(foregroundColor: Link26Surface.textPrimary),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.used,
    required this.limit,
    required this.embedded,
  });

  final int used;
  final int limit;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final progress = limit > 0 ? used / limit : 0.0;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: EdgeInsets.fromLTRB(embedded ? 16 : 44, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 약 정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Link26Surface.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Link26Surface.outline,
                      color: Link26Surface.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$used/$limit',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Link26Surface.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '오전 4시에 초기화됩니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 첫 AI 말풍선 — [timeLabel]은 접속 시각([AiChatSessionStore])과 동일 포맷.
class _AiWelcomeBubble extends StatelessWidget {
  const _AiWelcomeBubble({required this.timeLabel});

  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 32,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Link26Surface.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Link26Surface.textPrimary,
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: '안녕하세요! 약 정보를 도와드리겠습니다.\n\n'),
                  const TextSpan(
                    text:
                        '처방전이나 약 사진을 업로드하시면 약 정보를 확인해드립니다.\n\n',
                  ),
                  const TextSpan(text: '💡 '),
                  const TextSpan(
                    text: '사진 촬영 팁:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.accent,
                    ),
                  ),
                  const TextSpan(text: '\n'),
                  const TextSpan(
                    text:
                        '- 약 이름과 용량이 선명하게 보이도록 촬영해 주세요\n'
                        '- 처방전의 경우 약 이름 부분이 잘 보이게 촬영해 주세요\n'
                        '- 밝은 곳에서 촬영하시면 더 정확합니다',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Link26Surface.chipTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Link26Surface.accent,
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'AI가 제공하는 정보는 참고용입니다. 정확한 복용 방법은 의사나 약사와 상담하세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Link26Surface.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onCamera,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Link26Surface.outline),
            ),
            child: InkWell(
              onTap: onCamera,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.photo_camera_outlined,
                  color: Link26Surface.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '약에 대해 궁금한 점을 물어보세요...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Link26Surface.outline),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Link26Surface.accent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = isUser ? Link26Surface.chipTint : Colors.white;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Link26Surface.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Link26Surface.textPrimary,
              ),
            ),
            if (message.cardTitle != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Link26Surface.badgeTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Link26Surface.outline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medication_outlined, color: Link26Surface.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.cardTitle!,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(message.cardSubtitle ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              message.time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
