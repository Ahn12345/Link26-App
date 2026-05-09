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
  static const _quotaUsed = 3;
  static const _quotaMax = 10;

  final controller = TextEditingController();
  final messages = <ChatMessage>[
    const ChatMessage(
      isUser: false,
      time: '오후 10:48',
      text:
          '안녕하세요! 약 정보를 도와드리겠습니다. 처방전이나 약 사진을 업로드하시면 약 정보를 확인해드립니다.\n\n📷 사진 촬영 팁\n• 약 이름과 용량이 선명하게 보이도록 촬영해주세요\n• 처방전은 약 이름이 잘 보이게 촬영해주세요\n• 밝은 곳에서 촬영하시면 더 정확합니다',
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
    final progress = _quotaUsed / _quotaMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 약 정보',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: const Color(0xFF0B6BFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_quotaUsed/$_quotaMax',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '오전 4시에 초기화됩니다',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _Bubble(message: messages[index]),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: const Color(0xFFEAF2FF),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0B6BFF), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI가 제공하는 정보는 참고용입니다. 증상이 있거나 약을 바꾸기 전에는 반드시 의사·약사와 상담하세요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.photo_camera_outlined),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '약에 대해 궁금한 점을 물어보세요...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: send,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF475569),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
