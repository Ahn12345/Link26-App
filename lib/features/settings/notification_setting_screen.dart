import 'package:flutter/material.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool all = false;
  bool message = false;
  bool family = false;
  bool notice = false;
  bool event = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Text('알림 설정', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '중요한 소식을 놓치지 않도록 알림을 설정해 보세요.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            _SwitchTile(
              icon: Icons.notifications_none,
              title: '전체 알림',
              subtitle: '모든 알림을 한 번에 설정합니다.',
              value: all,
              onChanged: (v) => setState(() {
                all = v;
                message = family = notice = event = v;
              }),
            ),
            const SizedBox(height: 22),
            const Text('알림 항목', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            _SwitchTile(
              icon: Icons.chat_bubble_outline,
              title: '메시지 알림',
              subtitle: '메시지 수신 시 알림을 받습니다.',
              value: message,
              onChanged: (v) => setState(() => message = v),
            ),
            _SwitchTile(
              icon: Icons.group_outlined,
              title: '가족 초대 알림',
              subtitle: '가족 구성원 초대 알림을 받습니다.',
              value: family,
              onChanged: (v) => setState(() => family = v),
            ),
            _SwitchTile(
              icon: Icons.campaign_outlined,
              title: '공지사항 알림',
              subtitle: '서비스 공지사항을 받습니다.',
              value: notice,
              onChanged: (v) => setState(() => notice = v),
            ),
            _SwitchTile(
              icon: Icons.card_giftcard,
              title: '이벤트 및 혜택 알림',
              subtitle: '이벤트 및 혜택 정보를 받습니다.',
              value: event,
              onChanged: (v) => setState(() => event = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              tileColor: Colors.white,
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('방해 금지 시간 설정', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('설정한 시간 동안 알림을 받지 않습니다.'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10),
        ],
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFF1F5F9),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
