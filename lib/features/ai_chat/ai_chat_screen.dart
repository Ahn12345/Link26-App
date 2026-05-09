import 'package:flutter/material.dart';

import 'package:link26_app/models/link_models.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key, this.showScaffold = true});

  static const routeName = '/ai-chat';

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final body = const _AiChatBody();
    if (!showScaffold) return body;
    return const Scaffold(body: _AiChatBody());
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
      isUser: false,
      time: '오전 10:48',
      text:
          '안녕하세요! 처방전 약 정보를 확인하는 방법을 안내해드릴게요.\n\n처방전이나 약 사진을 업로드하시면 약 정보를 확인해드릴 수 있어요.\n\n💡 사진 촬영 팁\n• 약 이름과 용량이 선명하게 보이도록 촬영해주세요\n• 처방전의 경우 약 이름 부분이 잘 보이게 촬영해주세요\n• 밝은 곳에서 촬영하시면 더 정확합니다',
    ),
    const ChatMessage(
      isUser: false,
      time: '오전 10:50',
      text: '사진을 확인했습니다! 🙂\n다음과 같은 약이 처방되었어요.',
      cardTitle: '아세트아미노펜 500mg',
      cardSubtitle: '1일 3회, 1회 3정, 식후 복용\n5일분 처방',
    ),
    const ChatMessage(
      isUser: true,
      time: '오전 10:51',
      text: '처방전 사진을 추가로 업로드합니다.',
    ),
    const ChatMessage(
      isUser: false,
      time: '오전 10:52',
      text:
          '추가로 업로드해주신 처방전도 확인했습니다! 아래 약이 추가로 처방되었어요.',
      cardTitle: '로라타딘 10mg',
      cardSubtitle: '1일 1정, 1일 1회, 취침 전 복용\n5일분 처방',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(ChatMessage(isUser: true, time: '방금', text: text));
      messages.add(
        const ChatMessage(
          isUser: false,
          time: '방금',
          text:
              '입력하신 내용을 바탕으로 복용 시간과 주의사항을 확인해볼게요. 정확한 진단이나 처방 변경은 의사·약사에게 꼭 확인해주세요.',
        ),
      );
    });
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '언제든지 궁금한 점을 물어보세요!',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
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
              itemBuilder: (context, index) => _Bubble(message: messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '궁금한 내용을 입력하세요...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFD7E4FF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined),
                ),
                FilledButton(
                  onPressed: send,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser ? const Color(0xFFEAF2FF) : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF0B6BFF),
                    child: Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E4FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: const TextStyle(height: 1.45, fontSize: 14),
                      ),
                      if (message.cardTitle != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7E4FF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.medication, color: Color(0xFF0B6BFF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.cardTitle!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      message.cardSubtitle ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 42, right: 6),
            child: Text(
              message.time,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
