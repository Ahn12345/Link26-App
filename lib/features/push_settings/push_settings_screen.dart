import 'package:flutter/material.dart';

import 'package:link26_app/core/services/notification_category_prefs.dart';

class PushSettingsScreen extends StatefulWidget {
  const PushSettingsScreen({super.key});
  static const routeName = '/push-settings';

  @override
  State<PushSettingsScreen> createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {
  bool _loading = true;
  bool all = true;
  bool message = true;
  bool family = true;
  bool notice = true;
  bool event = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await NotificationCategoryPrefs.messageEnabled();
    final f = await NotificationCategoryPrefs.familyEnabled();
    final n = await NotificationCategoryPrefs.noticeEnabled();
    final e = await NotificationCategoryPrefs.eventEnabled();
    if (!mounted) return;
    setState(() {
      message = m;
      family = f;
      notice = n;
      event = e;
      all = m && f && n && e;
      _loading = false;
    });
  }

  Future<void> _setAll(bool v) async {
    await NotificationCategoryPrefs.setAll(v);
    if (!mounted) return;
    setState(() {
      all = v;
      message = family = notice = event = v;
    });
  }

  Future<void> _setMessage(bool v) async {
    await NotificationCategoryPrefs.setMessage(v);
    if (!mounted) return;
    setState(() {
      message = v;
      all = message && family && notice && event;
    });
  }

  Future<void> _setFamily(bool v) async {
    await NotificationCategoryPrefs.setFamily(v);
    if (!mounted) return;
    setState(() {
      family = v;
      all = message && family && notice && event;
    });
  }

  Future<void> _setNotice(bool v) async {
    await NotificationCategoryPrefs.setNotice(v);
    if (!mounted) return;
    setState(() {
      notice = v;
      all = message && family && notice && event;
    });
  }

  Future<void> _setEvent(bool v) async {
    await NotificationCategoryPrefs.setEvent(v);
    if (!mounted) return;
    setState(() {
      event = v;
      all = message && family && notice && event;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '스위치는 기기에 저장됩니다. 서버 푸시(FCM) 연동 시 이 설정을 존중하도록 '
                  '백엔드와 맞출 수 있습니다.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                _SwitchCard(
                  icon: Icons.notifications_none,
                  title: '전체 알림',
                  subtitle: '네 가지 알림을 한 번에 설정합니다.',
                  value: all,
                  onChanged: _setAll,
                ),
                const SizedBox(height: 24),
                const Text(
                  '알림 항목',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _GroupedSwitches(
                  items: [
                    _SwitchItem(
                      Icons.chat_bubble_outline,
                      '메시지 알림',
                      '메시지 수신 시 알림을 받습니다.',
                      message,
                      _setMessage,
                      const Color(0xFFEAF2FF),
                      const Color(0xFF0B6BFF),
                    ),
                    _SwitchItem(
                      Icons.groups_outlined,
                      '가족 초대 알림',
                      '가족 구성원 초대 알림을 받습니다.',
                      family,
                      _setFamily,
                      const Color(0xFFE9FBEF),
                      const Color(0xFF16A34A),
                    ),
                    _SwitchItem(
                      Icons.campaign_outlined,
                      '공지사항 알림',
                      '서비스 공지사항을 받습니다.',
                      notice,
                      _setNotice,
                      const Color(0xFFFFF3E8),
                      const Color(0xFFF97316),
                    ),
                    _SwitchItem(
                      Icons.card_giftcard,
                      '이벤트 및 혜택 알림',
                      '이벤트 및 혜택 정보를 받습니다.',
                      event,
                      _setEvent,
                      const Color(0xFFFFEAF3),
                      const Color(0xFFEC4899),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _MenuCard(
                  icon: Icons.notifications_off_outlined,
                  title: '방해 금지 시간 설정',
                  subtitle: '준비 중입니다.',
                ),
              ],
            ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
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
  Widget build(BuildContext context) => _Card(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Icon(icon, color: const Color(0xFF111827), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _GroupedSwitches extends StatelessWidget {
  const _GroupedSwitches({required this.items});
  final List<_SwitchItem> items;
  @override
  Widget build(BuildContext context) => _Card(
        padding: EdgeInsets.zero,
        child: Column(
          children: items.map((e) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: e.bg,
                    child: Icon(e.icon, color: e.fg, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.subtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: e.value, onChanged: e.onChanged),
                ],
              ),
            );
          }).toList(),
        ),
      );
}

class _SwitchItem {
  const _SwitchItem(
    this.icon,
    this.title,
    this.subtitle,
    this.value,
    this.onChanged,
    this.bg,
    this.fg,
  );
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color bg;
  final Color fg;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => _Card(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 32),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}
