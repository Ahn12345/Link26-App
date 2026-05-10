import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/features/family/family_account_screen.dart';
import 'package:link26_app/features/more/guide_screen.dart';
import 'package:link26_app/features/settings/display_setting_screen.dart';
import 'package:link26_app/features/settings/notification_setting_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, this.showScaffold = true});

  static const routeName = '/more';

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final bg = showScaffold ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent;
    final body = ColoredBox(color: bg, child: const _MoreBody());
    if (!showScaffold) return body;
    return Scaffold(backgroundColor: bg, body: body);
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 88;
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
        children: [
          Center(
            child: DecodedAssetImage(
              ImageAssets.logo,
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          const Text('더보기', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF38BDF8),
                  child: Text('김', style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('김건강', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('kimhealth@example.com'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _MenuTile(
            icon: Icons.group_outlined,
            title: '가족 계정',
            subtitle: '가족 구성원 관리',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const FamilyAccountScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.notifications_none,
            title: '알림 설정',
            subtitle: '전화/푸시 알림 설정',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const NotificationSettingScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.text_fields,
            title: '표시 설정',
            subtitle: '글자 크기, 화면 구성',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const DisplaySettingScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.help_outline,
            title: '도움말',
            subtitle: '사용 가이드 및 FAQ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const GuideScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF1F5F9),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
