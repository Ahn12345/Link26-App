import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
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
      child: Link26ResponsiveList(
        bottomInset: bottomPad + 4,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  '더보기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    color: Link26Surface.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              DecodedAssetImage(
                ImageAssets.applogo,
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Link26ElevatedCard(
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Link26Surface.chipTint,
                  child: Text('김', style: TextStyle(color: Link26Surface.accent, fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('김건강', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Link26Surface.textPrimary)),
                      SizedBox(height: 4),
                      Text('kimhealth@example.com', style: TextStyle(color: Link26Surface.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Link26SectionHeader(title: '메뉴'),
          const SizedBox(height: 8),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Link26ElevatedCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Link26Surface.chipTint,
                    child: Icon(icon, color: Link26Surface.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Link26Surface.textPrimary)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 13, color: Link26Surface.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Link26Surface.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
