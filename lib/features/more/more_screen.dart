import 'package:flutter/material.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/features/home/home_notification_center_screen.dart';
import 'package:link26_app/features/family/family_account_screen.dart';
import 'package:link26_app/features/more/guide_screen.dart';
import 'package:link26_app/features/settings/display_setting_screen.dart';
import 'package:link26_app/features/settings/emergency_contact_screen.dart';
import 'package:link26_app/features/settings/notification_setting_screen.dart';
import 'package:link26_app/l10n/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, this.showScaffold = true});

  static const routeName = '/more';

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final bg = showScaffold ? Link26UnifiedPage.background : Colors.transparent;
    final body = ColoredBox(
      color: bg,
      child: _MoreBody(l10n: AppLocalizations.of(context)),
    );
    if (!showScaffold) return body;
    return Scaffold(backgroundColor: bg, body: body);
  }
}

class _MoreBody extends StatefulWidget {
  const _MoreBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_MoreBody> createState() => _MoreBodyState();
}

class _MoreBodyState extends State<_MoreBody> {
  LocalUserRecord? _user;
  bool _loading = true;
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    LocalUserRecord? loaded;
    var session = false;
    try {
      session = await AuthSession.isSignedIn();
      if (session) {
        var phone = await AuthSession.activePhoneDigits();
        phone ??= await UserLocalRepository.singleUserPhoneDigits();
        if (phone != null && phone.isNotEmpty) {
          loaded = await UserLocalRepository.findUserByPhone(phone);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _sessionActive = session;
          _user = loaded;
          _loading = false;
        });
      }
    }
  }

  String _initialFromName(String name) {
    final t = UserLocalRepository.normalizeDisplayName(name);
    if (t.isEmpty) return '?';
    final first = t.runes.first;
    return String.fromCharCode(first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final bottomPad = MediaQuery.of(context).padding.bottom + 88;
    final w = MediaQuery.sizeOf(context).width;

    final displayName = UserLocalRepository.normalizeDisplayName(
      _user?.displayName ?? '',
    );
    final email = (_user?.email ?? '').trim();

    final showName = displayName.isNotEmpty
        ? displayName
        : (_loading
            ? '…'
            : (_sessionActive ? '이름 없음' : '로그인 후 표시'));
    final showEmail = email.isNotEmpty
        ? email
        : (_loading
            ? ''
            : (_sessionActive ? '이메일 없음' : '가입 시 입력한 이메일이 여기에 표시됩니다'));
    final initial = displayName.isNotEmpty
        ? _initialFromName(displayName)
        : '?';

    return SafeArea(
      child: Link26ResponsiveList(
        bottomInset: bottomPad + 4,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '더보기',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Link26ResponsiveUi.screenHeadline(w),
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    color: Link26Surface.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              IconButton(
                tooltip: '알림',
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => HomeNotificationCenterScreen(
                        doseAlarms: const [],
                        onListsChanged: () {},
                      ),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  foregroundColor: Link26Surface.textSecondary,
                  backgroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 26),
              ),
            ],
          ),
          SizedBox(height: Link26ResponsiveUi.gapXl(w)),
          Link26ElevatedCard(
            padding: EdgeInsets.all(Link26ResponsiveUi.profileCardPadding(w)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: Link26ResponsiveUi.profileAvatarRadius(w),
                  backgroundColor: Link26Surface.chipTint,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: Link26Surface.accent,
                      fontSize: Link26ResponsiveUi.menuProfileInitial(w),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: Link26ResponsiveUi.profileRowGap(w)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showName,
                        style: TextStyle(
                          fontSize: Link26ResponsiveUi.menuProfileName(w),
                          fontWeight: FontWeight.w900,
                          color: Link26Surface.textPrimary,
                        ),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapXs(w)),
                      Text(
                        showEmail,
                        style: TextStyle(
                          color: Link26Surface.textSecondary,
                          fontSize: Link26ResponsiveUi.menuProfileEmail(w),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Link26ResponsiveUi.gapLg(w)),
          const Link26SectionHeader(title: '메뉴'),
          SizedBox(height: Link26ResponsiveUi.gapSm(w)),
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
            icon: Icons.phone_in_talk_outlined,
            title: l10n.settingsEmergencyContact,
            subtitle: l10n.settingsEmergencyContactSubtitle,
            onTap: () => Navigator.of(context).pushNamed(
              EmergencyContactScreen.routeName,
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
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(bottom: Link26ResponsiveUi.menuTileBottomGap(w)),
      child: Link26ElevatedCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Link26UnifiedPage.frameRadius),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Link26ResponsiveUi.menuTileHPadding(w),
                vertical: Link26ResponsiveUi.menuTileVPadding(w),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Link26Surface.chipTint,
                    child: Icon(icon, color: Link26Surface.accent),
                  ),
                  SizedBox(width: Link26ResponsiveUi.gapMd(w)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Link26Surface.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: Link26ResponsiveUi.menuTileSubtitle(w),
                            color: Link26Surface.textSecondary,
                          ),
                        ),
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
