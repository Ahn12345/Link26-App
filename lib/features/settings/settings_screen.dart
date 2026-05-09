import 'package:flutter/material.dart';
import '../push_settings/push_settings_screen.dart';
import '../family_accounts_screen.dart';
import '../display_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정 설정'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        _ProfileHeader(),
        const SizedBox(height: 20),
        const Text('개인 정보', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        _InfoCard(items: const [
          _RowItem(Icons.person_outline, '이름', '김건강'),
          _RowItem(Icons.email_outlined, '이메일', 'kimhealth@example.com'),
          _RowItem(Icons.calendar_month_outlined, '가입일', '2024.05.20'),
          _RowItem(Icons.language, '언어', '한국어'),
        ]),
        const SizedBox(height: 18),
        const Text('설정', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        _MenuCard(items: [
          _MenuItem(Icons.groups_outlined, '계정 관리', '가족 계정 및 프로필 관리', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyAccountsScreen()))),
          _MenuItem(Icons.notifications_none, '알림 설정', '전화/일반 알림 설정', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PushSettingsScreen()))),
          _MenuItem(Icons.call_outlined, '긴급 연락처 관리', '보호자 연락처 관리', () {}),
          _MenuItem(Icons.text_fields, '표시 설정', '테마, 글자 크기, 화면 구성', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisplaySettingsScreen()))),
          _MenuItem(Icons.palette_outlined, '테마 설정', '라이트/다크 모드 설정', () {}),
          _MenuItem(Icons.privacy_tip_outlined, '개인정보 및 보안', '개인정보, 보안 설정', () {}),
          _MenuItem(Icons.info_outline, '앱 정보', '버전 정보, 이용 약관', () {}),
          _MenuItem(Icons.logout, '로그아웃', '현재 계정에서 로그아웃', () {}),
        ]),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: () {}, child: const Text('저장')),
        OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('계정 삭제')),
      ]),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Card(child: Row(children: [
        Stack(children: const [CircleAvatar(radius: 44, backgroundColor: Color(0xFF0B6BFF), child: Text('김', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900))), Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 15, backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.camera_alt, size: 16)))]),
        const SizedBox(width: 18),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('김건강', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(width: 8), Text('수정', style: TextStyle(color: Color(0xFF0B6BFF)))]), SizedBox(height: 4), Text('kimhealth@example.com', style: TextStyle(color: Color(0xFF475569))), SizedBox(height: 8), Row(children: [Icon(Icons.security, size: 16, color: Color(0xFF64748B)), SizedBox(width: 4), Text('2단계 인증 사용 중', style: TextStyle(color: Color(0xFF64748B)))])])),
      ]));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<_RowItem> items;
  @override
  Widget build(BuildContext context) => _Card(padding: EdgeInsets.zero, child: Column(children: items.map((e) => ListTile(leading: Icon(e.icon, color: const Color(0xFF64748B)), title: Text(e.title), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(e.value, style: const TextStyle(color: Color(0xFF64748B))), const Icon(Icons.chevron_right)]))).toList()));
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;
  @override
  Widget build(BuildContext context) => _Card(padding: EdgeInsets.zero, child: Column(children: items.map((e) => ListTile(leading: Icon(e.icon, color: const Color(0xFF64748B)), title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(e.subtitle), trailing: const Icon(Icons.chevron_right), onTap: e.onTap)).toList()));
}

class _RowItem { const _RowItem(this.icon, this.title, this.value); final IconData icon; final String title; final String value; }
class _MenuItem { const _MenuItem(this.icon, this.title, this.subtitle, this.onTap); final IconData icon; final String title; final String subtitle; final VoidCallback onTap; }

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))]), child: child);
}
