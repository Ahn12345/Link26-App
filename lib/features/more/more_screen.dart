import 'package:flutter/material.dart';

import 'package:link26_app/features/family_accounts_screen.dart';
import 'package:link26_app/features/push_settings/push_settings_screen.dart';
import 'package:link26_app/features/settings/emergency_contact_screen.dart';
import 'package:link26_app/features/settings/settings_screen.dart';
import 'package:link26_app/models/link_models.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, this.showScaffold = true});

  static const routeName = '/more';

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final body = const _MoreBody();
    if (!showScaffold) return body;
    return const Scaffold(body: _MoreBody());
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody();

  static const family = [
    FamilyMember(
      name: '이효자',
      relation: '딸',
      phone: '010-1234-5678',
      avatarText: '이',
    ),
    FamilyMember(
      name: '박효자',
      relation: '아들',
      phone: '010-5678-1234',
      avatarText: '박',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 112,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Text(
                  'link26',
                  style: TextStyle(
                    fontSize: 42,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'LINK FOR HEALTH',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 44,
                  color: Color(0xFF1E3A8A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '더보기',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            ],
          ),
          const _ProfileCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '가족 구성원',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FamilyAccountsScreen(),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('추가'),
              ),
            ],
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const FamilyAccountsScreen(),
              ),
            ),
            child: const _FamilyCard(family: family),
          ),
          const SizedBox(height: 22),
          _MenuCard(
            items: [
              _MenuItem(
                Icons.notifications_none,
                '알림 설정',
                '전화/푸시 알림 설정',
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PushSettingsScreen(),
                  ),
                ),
              ),
              _MenuItem(
                Icons.call_outlined,
                '긴급 연락처',
                '보호자 연락처 관리/긴급 신고',
                () => Navigator.of(context).pushNamed(
                  EmergencyContactScreen.routeName,
                ),
              ),
              _MenuItem(
                Icons.settings_outlined,
                '설정',
                '앱 환경설정',
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
              _MenuItem(
                Icons.help_outline,
                '도움말',
                '사용 가이드 및 FAQ',
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const GuideScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: const [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFF38A9DB),
            child: Text(
              '김',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '김건강',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text('kimhealth@example.com', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family});

  final List<FamilyMember> family;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: family
            .map(
              (m) => Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: m.avatarText == '이'
                          ? const Color(0xFFFFD6E7)
                          : const Color(0xFFD8F6D9),
                      child: Text(
                        m.avatarText,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text('${m.relation} · ${m.phone}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Icon(item.icon, color: const Color(0xFF111827)),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: item.onTap,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.title, this.subtitle, this.onTap);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용 가이드')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            '링크를 더 스마트하게,\n쉽게 사용해보세요',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '링크의 주요 기능과 사용 방법을 안내해 드립니다.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          SizedBox(height: 30),
          _GuideTile(
            title: '계정 및 프로필 설정',
            subtitle:
                '프로필 정보를 확인하고 가족 구성원을 추가하여 편리하게 관리할 수 있습니다.',
          ),
          _GuideTile(
            title: '가족 구성원 추가',
            subtitle: '가족 구성원을 추가하면 연락처와 알림을 공유할 수 있습니다.',
          ),
          _GuideTile(
            title: '연락처 관리',
            subtitle: '가족 및 보호자 연락처를 등록하고 쉽게 관리할 수 있습니다.',
          ),
          _GuideTile(
            title: '알림 설정',
            subtitle: '중요한 알림을 놓치지 않도록 알림 설정을 관리해보세요.',
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
