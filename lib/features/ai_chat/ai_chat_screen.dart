import 'package:flutter/material.dart';

import 'package:link26_app/models/link_models.dart';

/// 카카오 functional 스타일 AI 채팅 + GitHub용 [showScaffold] / 라우트 호환.
class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key, this.showScaffold = true});

  static const routeName = '/ai-chat';

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final body = ColoredBox(color: bg, child: const _AiChatBody());
    if (!showScaffold) return body;
    return Scaffold(backgroundColor: bg, body: body);
  }
}

class _AiChatBody extends StatefulWidget {
  const _AiChatBody();

  @override
  State<_AiChatBody> createState() => _AiChatBodyState();
}

class _AiChatBodyState extends State<_AiChatBody> {
  final controller = TextEditingController();
  final messages = <ChatMessage>[
    const ChatMessage(
      text:
          '안녕하세요! 처방전 약 정보를 확인하는 방법을 안내해드릴게요.\n\n처방전이나 약 사진을 업로드하시면 약 정보를 확인해드릴 수 있어요.\n\n💡 사진 촬영 팁\n• 약 이름과 용량이 선명하게 보이도록 촬영해주세요\n• 처방전의 경우 약 이름 부분이 잘 보이게 촬영해주세요\n• 밝은 곳에서 촬영하시면 더 정확합니다',
      isUser: false,
      time: '오전 10:48',
    ),
    const ChatMessage(
      text: '사진을 확인했습니다! 🙂\n다음과 같은 약이 처방되었어요.',
      isUser: false,
      time: '오전 10:50',
      cardTitle: '아세트아미노펜 500mg',
      cardSubtitle: '1일 3회, 1회 3정, 식후 복용\n5일분 처방',
    ),
    const ChatMessage(
      text: '처방전 사진을 추가로 업로드합니다.',
      isUser: true,
      time: '오전 10:51',
    ),
    const ChatMessage(
      text:
          '추가로 업로드해주신 처방전도 확인했습니다! 🙂\n아래 약이 추가로 처방되었어요.',
      isUser: false,
      time: '오전 10:52',
      cardTitle: '로라타딘 10mg',
      cardSubtitle: '1일 1정, 1일 1회, 취침 전 복용\n5일분 처방',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(ChatMessage(isUser: true, time: '지금', text: text));
      messages.add(
        const ChatMessage(
          text:
              '입력하신 내용을 확인했어요. 실제 REST API가 연결되면 서버 응답으로 교체하면 됩니다.',
          isUser: false,
          time: '지금',
        ),
      );
    });
    controller.clear();
  }

  void addImageMessage() {
    setState(() {
      messages.add(
        const ChatMessage(
          text: '처방전 사진을 업로드했습니다.',
          isUser: true,
          time: '지금',
        ),
      );
      messages.add(
        const ChatMessage(
          text:
              '사진 업로드 기능이 실행되었습니다. image_picker와 REST API 업로드를 연결하면 실제 분석이 가능합니다.',
          isUser: false,
          time: '지금',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  backgroundColor: Color(0xFF0B6BFF),
                  child: Icon(Icons.smart_toy, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 처방전 도우미',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '언제든지 궁금한 점을 물어보세요!',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => messages.clear()),
                  icon: const Icon(Icons.add),
                  label: const Text('새 대화'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '궁금한 내용을 입력하세요...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(onPressed: addImageMessage, icon: const Icon(Icons.image_outlined)),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0B6BFF),
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser ? const Color(0xFFEAF3FF) : Colors.white;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7E6FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.text),
              if (message.cardTitle != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFD7FF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medication_outlined, color: Color(0xFF0B6BFF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.cardTitle!, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(message.cardSubtitle ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                message.time,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
