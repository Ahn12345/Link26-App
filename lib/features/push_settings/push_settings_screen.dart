import 'package:flutter/material.dart';

class PushSettingsScreen extends StatefulWidget {
  const PushSettingsScreen({super.key});
  static const routeName = '/push-settings';

  @override
  State<PushSettingsScreen> createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {
  bool all = false;
  bool message = false;
  bool family = false;
  bool notice = false;
  bool event = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('중요한 소식을 놓치지 않도록 알림을 설정해 보세요.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 26),
          _SwitchCard(icon: Icons.notifications_none, title: '전체 알림', subtitle: '모든 알림을 한 번에 설정합니다.', value: all, onChanged: (v) => setState(() { all = v; message = v; family = v; notice = v; event = v; })),
          const SizedBox(height: 24),
          const Text('알림 항목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _GroupedSwitches(items: [
            _SwitchItem(Icons.chat_bubble_outline, '메시지 알림', '메시지 수신 시 알림을 받습니다.', message, (v) => setState(() => message = v), const Color(0xFFEAF2FF), const Color(0xFF0B6BFF)),
            _SwitchItem(Icons.groups_outlined, '가족 초대 알림', '가족 구성원 초대 알림을 받습니다.', family, (v) => setState(() => family = v), const Color(0xFFE9FBEF), const Color(0xFF16A34A)),
            _SwitchItem(Icons.campaign_outlined, '공지사항 알림', '서비스 공지사항을 받습니다.', notice, (v) => setState(() => notice = v), const Color(0xFFFFF3E8), const Color(0xFFF97316)),
            _SwitchItem(Icons.card_giftcard, '이벤트 및 혜택 알림', '이벤트 및 혜택 정보를 받습니다.', event, (v) => setState(() => event = v), const Color(0xFFFFEAF3), const Color(0xFFEC4899)),
          ]),
          const SizedBox(height: 22),
          _MenuCard(icon: Icons.notifications_off_outlined, title: '방해 금지 시간 설정', subtitle: '설정한 시간 동안 알림을 받지 않습니다.'),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => _Card(child: Row(children: [
        CircleAvatar(radius: 28, backgroundColor: const Color(0xFFF1F5F9), child: Icon(icon, color: const Color(0xFF111827), size: 30)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(fontSize: 16, color: Color(0xFF334155)))])),
        Switch(value: value, onChanged: onChanged),
      ]));
}

class _GroupedSwitches extends StatelessWidget {
  const _GroupedSwitches({required this.items});
  final List<_SwitchItem> items;
  @override
  Widget build(BuildContext context) => _Card(padding: EdgeInsets.zero, child: Column(children: items.map((e) => Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))), child: Row(children: [CircleAvatar(radius: 28, backgroundColor: e.bg, child: Icon(e.icon, color: e.fg, size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(e.subtitle, style: const TextStyle(fontSize: 16, color: Color(0xFF334155)))])), Switch(value: e.value, onChanged: e.onChanged)]))).toList()));
}

class _SwitchItem {
  const _SwitchItem(this.icon, this.title, this.subtitle, this.value, this.onChanged, this.bg, this.fg);
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color bg;
  final Color fg;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => _Card(child: Row(children: [CircleAvatar(radius: 28, backgroundColor: const Color(0xFFF1F5F9), child: Icon(icon, size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 16, color: Color(0xFF334155)))])), const Icon(Icons.chevron_right, size: 32)]));
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 16, offset: const Offset(0, 4))]), child: child);
}
