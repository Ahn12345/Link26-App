import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/app_build_fingerprint.dart';
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
import 'package:link26_app/core/services/dose_reminder_notifications.dart';
import 'package:link26_app/core/services/reminder_channel_prefs.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';
import 'package:link26_app/features/more/phone_reminder_settings_screen.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 배포·스토어 앱과 소스 트리가 같은지 확인용(더보기 하단에 표시).
const int kMoreScreenLayoutRevision = 5;

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

class _MoreBodyState extends State<_MoreBody> with WidgetsBindingObserver {
  LocalUserRecord? _user;
  bool _loading = true;
  bool _sessionActive = false;

  bool _pushOn = true;
  TimeOfDay _pushTime = const TimeOfDay(hour: 9, minute: 0);
  bool _phoneOn = false;
  String _phoneTimeHm = '10:00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _loadReminderPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadProfile();
      _loadReminderPrefs();
    }
  }

  Future<void> _loadReminderPrefs() async {
    final po = await ReminderChannelPrefs.pushEnabled();
    final pt = await ReminderChannelPrefs.pushTime();
    final pho = await ReminderChannelPrefs.phoneEnabled();
    final phm = await ReminderChannelPrefs.phoneTimeHm();
    if (!mounted) return;
    setState(() {
      _pushOn = po;
      _pushTime = pt;
      _phoneOn = pho;
      _phoneTimeHm = phm;
    });
  }

  Future<void> _pickPushTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pushTime,
    );
    if (picked == null) return;
    await ReminderChannelPrefs.setPushTime(picked);
    unawaited(DoseReminderNotifications.rescheduleFromPrefs());
    if (mounted) setState(() => _pushTime = picked);
  }

  Future<void> _loadProfile() async {
    LocalUserRecord? loaded;
    var session = false;
    try {
      session = await AuthSession.isSignedIn();
      if (session) {
        loaded = await UserLocalRepository.loadSignedInUserRecord();
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
    final emailRaw = _user == null ? '' : UserLocalRepository.profileEmailLabel(_user!);
    final email = emailRaw.trim();

    final showName = displayName.isNotEmpty
        ? displayName
        : (_loading
            ? '…'
            : (_sessionActive ? '이름 없음' : '로그인 후 표시'));
    final showEmail = email.isNotEmpty
        ? email
        : (_loading
            ? ''
            : (_sessionActive ? '연락처 정보 없음' : '가입 시 입력한 이메일이 여기에 표시됩니다'));
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
          const Link26SectionHeader(title: '복용 알림'),
          SizedBox(height: Link26ResponsiveUi.gapSm(w)),
          _ReminderChannelCard(
            w: w,
            icon: Icons.notifications_active_outlined,
            title: '푸시 복용 알림',
            subtitle:
                '${_pushTime.format(context)} · 홈 카드 + 매일 같은 시각 기기 알림(앱 종료 후에도)',
            value: _pushOn,
            onChanged: (v) async {
              await ReminderChannelPrefs.setPushEnabled(v);
              unawaited(DoseReminderNotifications.rescheduleFromPrefs());
              if (mounted) setState(() => _pushOn = v);
            },
            onPickTime: _pickPushTime,
          ),
          _ReminderChannelCard(
            w: w,
            icon: Icons.phone_in_talk_outlined,
            title: '전화 알림',
            subtitle: _phoneOn
                ? '$_phoneTimeHm · 홈 카드 + 강조 기기 알림 (실제 전화·착신 아님)'
                : '꺼짐 · 눌러서 설정',
            value: _phoneOn,
            onChanged: (v) async {
              await ReminderChannelPrefs.setPhoneEnabled(v);
              unawaited(DoseReminderNotifications.rescheduleFromPrefs());
              if (mounted) {
                setState(() => _phoneOn = v);
                await _loadReminderPrefs();
              }
            },
            onPickTime: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PhoneReminderSettingsScreen(),
                ),
              );
              if (mounted) await _loadReminderPrefs();
            },
            timeHint: '시각·멘트',
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              bottom: Link26ResponsiveUi.gapSm(w),
            ),
            child: Text(
              '※ 복용 알림: 매일 설정 시각에 로컬 알림(상태바)을 보냅니다. 알림 권한을 허용해 주세요. '
              '실제 전화를 걸거나 받는 기능은 통신사·콜 API·백엔드가 있어야 하며, 지금 앱은 알림으로만 안내합니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Link26Surface.textMuted,
              ),
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
            subtitle: '메시지·가족·공지 등 세부 항목',
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
          if (_sessionActive) ...[
            SizedBox(height: Link26ResponsiveUi.gapLg(w)),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  await AuthSession.signOut();
                  if (!context.mounted) return;
                  await Navigator.of(context).pushNamedAndRemoveUntil(
                    AuthWelcomeScreen.routeName,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.signOut),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          SizedBox(height: Link26ResponsiveUi.gapLg(w)),
          Center(
            child: Text(
              kDebugMode
                  ? 'DEBUG · 빌드$kAppBuildNumber #$kAppBuildTag · 더보기#$kMoreScreenLayoutRevision'
                  : '빌드 $kAppBuildNumber · 더보기 UI #$kMoreScreenLayoutRevision',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Link26Surface.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderChannelCard extends StatelessWidget {
  const _ReminderChannelCard({
    required this.w,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.onPickTime,
    this.timeHint,
  });

  final double w;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickTime;
  final String? timeHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Link26ResponsiveUi.menuTileBottomGap(w)),
      child: Link26ElevatedCard(
        padding: EdgeInsets.symmetric(
          horizontal: Link26ResponsiveUi.menuTileHPadding(w),
          vertical: Link26ResponsiveUi.menuTileVPadding(w) * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Link26Surface.chipTint,
                  child: Icon(icon, color: Link26Surface.accent),
                ),
                SizedBox(width: Link26ResponsiveUi.gapMd(w)),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                                color: Link26Surface.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Link26Surface.accent,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPickTime,
                child: Text(timeHint ?? '시각 변경'),
              ),
            ),
          ],
        ),
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
