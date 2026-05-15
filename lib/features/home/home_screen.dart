import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:link26_app/core/database/home_notification_repository.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/ai_chat_home_alert_notifier.dart';
import 'package:link26_app/core/services/main_shell_tab_bus.dart';
import 'package:link26_app/features/home/home_notification_center_screen.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/dose_reminder_completion_store.dart';
import 'package:link26_app/core/services/hira_link_service.dart';
import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/link26_bff_advice.dart';
import 'package:link26_app/core/services/link26_remote_bff_bootstrap.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/core/services/reminder_channel_prefs.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/widgets/link26_vector_icons.dart';
import 'package:link26_app/features/alarms/all_alarms_screen.dart';
import 'package:link26_app/features/home/my_medicines_period_screen.dart';
import 'package:link26_app/features/search/pill_search_screen.dart';
import 'package:link26_app/models/alarm_item.dart';
import 'package:link26_app/models/medicine.dart';

/// [MainShell] 홈 탭 — 카카오 functional 데이터 흐름 + 고퀄 카드 UI.
class HomeDashboardContent extends StatefulWidget {
  const HomeDashboardContent({super.key});

  @override
  State<HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<HomeDashboardContent> {
  List<Medicine> medicines = [];
  List<AlarmItem> _doseAlarms = [];

  /// 종 아이콘 배지: 미읽음 AI 알림 + 미완료 복용 건수.
  int _bellBadgeCount = 0;

  String _normMedName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _doseAlarmDateLabel() {
    final now = DateTime.now();
    const w = ['월', '화', '수', '목', '금', '토', '일'];
    return '${now.year}년 ${now.month}월 ${now.day}일 (${w[now.weekday - 1]})';
  }

  List<AlarmItem> _buildDoseAlarms(
    List<Medicine> meds,
    Set<String> completedNorms,
  ) {
    if (meds.isEmpty) return [];
    final dateStr = _doseAlarmDateLabel();
    return meds
        .map(
          (m) => AlarmItem(
            date: dateStr,
            time: _alarmTimeFromMedicine(m),
            medicineName: m.name,
            dose: m.dose,
            type: AlarmType.app,
            completed: completedNorms.contains(_normMedName(m.name)),
          ),
        )
        .toList();
  }

  Future<List<AlarmItem>> _composeDoseAlarms(
    List<Medicine> meds,
    Set<String> completedNorms,
  ) async {
    final base = _buildDoseAlarms(meds, completedNorms);
    final dateStr = _doseAlarmDateLabel();
    final prefix = <AlarmItem>[];
    if (await ReminderChannelPrefs.pushEnabled()) {
      final t = await ReminderChannelPrefs.pushTimeHm();
      const name = '푸시 복용 알림';
      prefix.add(
        AlarmItem(
          date: dateStr,
          time: t,
          medicineName: name,
          dose: '앱 알림',
          type: AlarmType.app,
          completed: completedNorms.contains(_normMedName(name)),
        ),
      );
    }
    final suffix = <AlarmItem>[];
    if (await ReminderChannelPrefs.phoneEnabled()) {
      final t = await ReminderChannelPrefs.phoneTimeHm();
      final msg = (await ReminderChannelPrefs.phoneMessage()).trim();
      final name = msg.isEmpty ? '전화 복용 알림' : msg;
      suffix.add(
        AlarmItem(
          date: dateStr,
          time: t,
          medicineName: name,
          dose: '전화 안내',
          type: AlarmType.call,
          completed: completedNorms.contains(_normMedName(name)),
        ),
      );
    }
    return [...prefix, ...base, ...suffix];
  }

  String _alarmTimeFromMedicine(Medicine m) {
    final t = m.time.trim();
    if (t.isEmpty || t == '-') return '09:00';
    final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(t);
    if (match != null) return match.group(1)!;
    return t;
  }

  @override
  void initState() {
    super.initState();
    HomeNotificationRepository.revision.addListener(_onBellDepsChanged);
    AiChatHomeAlertNotifier.instance.addListener(_onBellDepsChanged);
    Link26RemoteBffBootstrap.revision.addListener(_onRemoteBffRevision);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapMedicines();
      if (!mounted) return;
      unawaited(AiChatHomeAlertNotifier.instance.refreshBannerFromDb());
      unawaited(_refreshBellBadge());
    });
  }

  void _onBellDepsChanged() {
    unawaited(_refreshBellBadge());
  }

  void _onRemoteBffRevision() {
    if (!mounted) return;
    unawaited(_bootstrapMedicines());
  }

  @override
  void dispose() {
    HomeNotificationRepository.revision.removeListener(_onBellDepsChanged);
    AiChatHomeAlertNotifier.instance.removeListener(_onBellDepsChanged);
    Link26RemoteBffBootstrap.revision.removeListener(_onRemoteBffRevision);
    super.dispose();
  }

  Future<void> _refreshBellBadge() async {
    final aiUnread = await HomeNotificationRepository.unreadCountAiChat();
    final systemUnread =
        await HomeNotificationRepository.unreadCountSystemSync();
    final pendingDose = _doseAlarms.where((a) => !a.completed).length;
    if (mounted) {
      setState(() => _bellBadgeCount = aiUnread + systemUnread + pendingDose);
    }
  }

  Future<void> _dismissAiChatBannerAndRefresh() async {
    await AiChatHomeAlertNotifier.instance.dismiss();
    if (!mounted) return;
    await _refreshBellBadge();
  }

  Future<void> _openAiChatFromBannerAndRefresh() async {
    await AiChatHomeAlertNotifier.instance.dismiss();
    if (!mounted) return;
    MainShellTabBus.goTo(1);
    await _refreshBellBadge();
  }

  Future<void> _openNotificationCenter() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HomeNotificationCenterScreen(
          doseAlarms: _doseAlarms,
          onListsChanged: () {
            setState(() {});
            unawaited(_refreshBellBadge());
          },
        ),
      ),
    );
    if (mounted) await _refreshBellBadge();
  }

  /// 세션 사용자 기준 전화(숫자) — BFF·복약 동기화.
  Future<String> _phoneForNhisSync() async {
    if (!await AuthSession.isSignedIn()) return '';
    final u = await UserLocalRepository.loadSignedInUserRecord();
    if (u != null && u.phoneDigits.length >= 10) {
      return u.phoneDigits.replaceAll(RegExp(r'\D'), '');
    }
    final session = await AuthSession.activePhoneDigits();
    if (session != null && session.isNotEmpty) {
      return session.replaceAll(RegExp(r'\D'), '');
    }
    return await UserLocalRepository.singleUserPhoneDigits() ?? '';
  }

  Future<void> _bootstrapMedicines() async {
    await _reloadMedicinesFromStores();
    if (!mounted) return;

    final bffAdvice = Link26BffAdvice.takePendingNoticeKo();
    final previewParts = <String>[];
    if (bffAdvice != null && bffAdvice.isNotEmpty) {
      previewParts.add(bffAdvice);
    }

    final shouldSync =
        NhisRuntimeConfig.useMock || NhisRuntimeConfig.baseUrl.isNotEmpty;
    if (!shouldSync) {
      if (kDebugMode) {
        debugPrint(
          'NHIS: mock 꺼짐 + BFF 베이스 URL 비어 있음 — 복약 동기화 생략 '
          '(릴리스: NHIS_PRODUCTION_BASE_URL 또는 LINK26_REMOTE_CONFIG_URL JSON, '
          '디버그: .env NHIS_BASE_URL)',
        );
      }
      if (kReleaseMode && !NhisRuntimeConfig.useMock) {
        final hasManifest =
            Link26RemoteBffBootstrap.manifestUrl.trim().isNotEmpty;
        previewParts.add(
          hasManifest
              ? '운영 BFF 주소를 아직 불러오지 못했습니다. '
                  'Wi‑Fi·데이터 연결을 확인하거나 잠시 후 당겨서 새로고침해 보세요. '
                  'LINK26_REMOTE_CONFIG_URL 의 JSON에 '
                  '`{"nhisBffBases":["https://운영-BFF-주소"]}` 형식이 있는지 확인하세요. '
                  '또는 빌드에 --dart-define=NHIS_PRODUCTION_BASE_URL=… 를 넣을 수 있습니다.'
              : '운영 BFF 주소가 없어 서버에서 복약 정보를 불러오지 않습니다. '
                  '선택 ① dotenv에 LINK26_REMOTE_CONFIG_URL=https://…/link26-bff.json '
                  '(HTTPS JSON에 nhisBffBases) ② 빌드 시 '
                  '--dart-define=NHIS_PRODUCTION_BASE_URL=https://… '
                  '(.env의 NHIS_BASE_URL은 스토어 APK에서 쓰지 않습니다.)',
        );
      }
      if (mounted && previewParts.isNotEmpty) {
        await HomeNotificationRepository.insertSystemSyncNotice(
          title: AppLocalizations.of(context).homeNotificationSystemSyncTitle,
          preview: previewParts.join('\n\n'),
        );
        await _refreshBellBadge();
      }
      return;
    }

    final phone = await _phoneForNhisSync();
    if (kDebugMode && phone.isEmpty && !NhisRuntimeConfig.useMock) {
      debugPrint(
        'NHIS: 전화번호 없음 — 빈 phone으로 GET 시도 (base=${NhisRuntimeConfig.baseUrl})',
      );
    }
    final syncOut = await NhisMedicinesSync.syncNow(phoneDigits: phone);
    if (mounted) await _reloadMedicinesFromStores();
    if (mounted && syncOut.showBannerOnBootstrap) {
      final msg = syncOut.userMessageKo.trim();
      if (msg.isNotEmpty) previewParts.add(msg);
    }
    if (mounted && previewParts.isNotEmpty) {
      await HomeNotificationRepository.insertSystemSyncNotice(
        title: AppLocalizations.of(context).homeNotificationSystemSyncTitle,
        preview: previewParts.join('\n\n'),
      );
      await _refreshBellBadge();
    }
  }

  Future<void> _reloadMedicinesFromStores() async {
    final cached = await NhisMedicineCacheStore.loadMedicines();
    final manualNames = await LocalMedicineListStore.load();
    final byName = <String, Medicine>{};
    for (final m in cached) {
      final k = _normMedName(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final n in manualNames) {
      final k = _normMedName(n);
      if (k.isEmpty) continue;
      byName.putIfAbsent(
        k,
        () => Medicine(name: n.trim(), dose: '-', frequency: '-', time: '-'),
      );
    }
    final merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final completed = await DoseReminderCompletionStore.completedNormsToday();
    if (!mounted) return;
    final composed = await _composeDoseAlarms(merged, completed);
    if (!mounted) return;
    setState(() {
      medicines = merged;
      _doseAlarms = composed;
    });
  }

  Future<void> _refreshMedicinesFromServer() async {
    final shouldSync =
        NhisRuntimeConfig.useMock || NhisRuntimeConfig.baseUrl.isNotEmpty;
    if (shouldSync) {
      final phone = await _phoneForNhisSync();
      final syncOut = await NhisMedicinesSync.syncNow(phoneDigits: phone);
      if (mounted) await _reloadMedicinesFromStores();
      if (mounted && syncOut.showBannerOnBootstrap) {
        final msg = syncOut.userMessageKo.trim();
        if (msg.isNotEmpty) {
          await HomeNotificationRepository.insertSystemSyncNotice(
            title: AppLocalizations.of(context).homeNotificationSystemSyncTitle,
            preview: msg,
          );
          await _refreshBellBadge();
        }
      }
    } else {
      if (mounted) await _reloadMedicinesFromStores();
    }
  }

  /// 홈에서 심평원(BFF 틸코 플로우) 복약을 바로 반영합니다.
  Future<void> _importHiraMedicationsFromHome() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!await AuthSession.isSignedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeHiraMedicationsLoginRequired)),
      );
      return;
    }
    if (!mounted) return;
    if (NhisRuntimeConfig.useMock) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'NHIS_USE_MOCK=true 입니다. 실제 심평원·복약 데이터를 쓰려면 루트 .env에서 '
            'NHIS_USE_MOCK=false 로 바꾼 뒤 tool/sync_dotenv_asset.ps1 실행·앱 재빌드하고, '
            'PC에서 BFF를 띄운 뒤 다시 시도하세요.',
          ),
          duration: Duration(seconds: 8),
        ),
      );
      return;
    }
    if (!Link26BffIntegrationsClient.canCall) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeHiraMedicationsBffRequired)),
      );
      return;
    }
    final user = await UserLocalRepository.loadSignedInUserRecord();
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeHiraMedicationsLoginRequired)),
      );
      return;
    }
    await HiraLinkService.promptRrnAndSyncHiraMedications(
      context: context,
      user: user,
      announceSuccess: true,
    );
    if (!mounted) return;
    await _reloadMedicinesFromStores();
  }

  String _shortTime(DateTime? t) {
    if (t == null) return '';
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildAlarmPreviewCard(double w) {
    if (_doseAlarms.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: Link26ResponsiveUi.gapSm(w)),
        child: Text(
          '내 약 목록에 약이 있으면 여기에 오늘 복용 알림이 표시됩니다.',
          style: TextStyle(
            color: Link26Surface.textMuted,
            fontSize: Link26ResponsiveUi.bodySmall(w),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final pending = _doseAlarms.where((a) => !a.completed).toList();
    final item = pending.isNotEmpty ? pending.first : _doseAlarms.first;
    return _AlarmPreviewCard(
      item: item,
      onDone: () async {
        await DoseReminderCompletionStore.markCompleted(item.medicineName);
        if (!mounted) return;
        await _reloadMedicinesFromStores();
        unawaited(_refreshBellBadge());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = _doseAlarms.where((e) => e.completed).length;
    // [MainShell] extendBody: true 이면 본문이 하단 네비 뒤로 깔리므로 여백을 둡니다.
    final bottomPad =
        MediaQuery.of(context).padding.bottom + 88;
    final w = MediaQuery.sizeOf(context).width;

    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshMedicinesFromServer,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Link26ResponsiveUi.homeScrollPadH(w),
                Link26ResponsiveUi.homeScrollPadTop(w),
                Link26ResponsiveUi.homeScrollPadH(w),
                Link26ResponsiveUi.homeScrollBottomExtra(w) + bottomPad,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '건강한 하루를 시작하세요',
                          style: TextStyle(
                            fontSize: Link26ResponsiveUi.screenHeadline(w),
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            color: Link26Surface.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: _openNotificationCenter,
                              icon: Link26VectorIcons.bell(
                                Link26Surface.textSecondary,
                                size: 22,
                              ),
                            ),
                            if (_bellBadgeCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _bellBadgeCount > 99
                                        ? '99+'
                                        : '$_bellBadgeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                  _SearchPill(
                    onTap: () async {
                      await Navigator.of(context)
                          .pushNamed(PillSearchScreen.routeName);
                      if (mounted) await _reloadMedicinesFromStores();
                    },
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapXl(w)),
                  Link26ElevatedCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            title: '오늘 복용',
                            value:
                                '${_doseAlarms.isEmpty ? 0 : completed}/${_doseAlarms.length}',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: Link26ResponsiveUi.statDividerHeight(w),
                          color: Link26Surface.outline,
                        ),
                        Expanded(
                          child: _Stat(
                            title: '등록된 약',
                            value: '${medicines.length}개',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapLg(w)),
                  Link26SectionHeader(
                    title: '오늘의 알림',
                    action: '전체보기',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AllAlarmsScreen(alarms: _doseAlarms),
                      ),
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  ListenableBuilder(
                    listenable: AiChatHomeAlertNotifier.instance,
                    builder: (context, _) {
                      final n = AiChatHomeAlertNotifier.instance;
                      if (!n.visible) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: Link26ResponsiveUi.gapSm(w),
                        ),
                        child: _AiChatImageReplyHomeBanner(
                          title: n.title.isNotEmpty
                              ? n.title
                              : l10n.homeAiChatImageReplyTitle,
                          preview: n.preview,
                          timeLabel: _shortTime(n.at),
                          ctaLabel: l10n.homeAiChatImageReplyCta,
                          onOpenChat: () =>
                              unawaited(_openAiChatFromBannerAndRefresh()),
                          onDismiss: () =>
                              unawaited(_dismissAiChatBannerAndRefresh()),
                        ),
                      );
                    },
                  ),
                  _buildAlarmPreviewCard(w),
                  SizedBox(height: Link26ResponsiveUi.gapXl(w)),
                  Text(
                    '복용 완료',
                    style: TextStyle(
                      fontSize: Link26ResponsiveUi.subsectionHeader(w),
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  ..._doseAlarms
                      .where((e) => e.completed)
                      .map((e) => _CompletedTile(item: e)),
                  SizedBox(height: Link26ResponsiveUi.gapLg(w)),
                  Link26SectionHeader(
                    title: l10n.homeMyMedicinesTitle,
                    action: l10n.myMedicinesFullViewCta,
                    onAction: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MyMedicinesPeriodScreen(
                          onMedicinesChanged: () {
                            unawaited(_reloadMedicinesFromStores());
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  if (medicines.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: Link26ResponsiveUi.gapMd(w),
                        bottom: Link26ResponsiveUi.gapSm(w),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '검색·동기화로 약을 추가해 보세요',
                            style: TextStyle(
                              color: Link26Surface.textMuted,
                              fontSize: Link26ResponsiveUi.bodySmall(w),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!NhisRuntimeConfig.useMock) ...[
                            SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                            FilledButton.tonal(
                              onPressed: () =>
                                  unawaited(_importHiraMedicationsFromHome()),
                              child: Text(l10n.homeHiraMedicationsImport),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...medicines.map((m) => _MedicineTile(medicine: m)),
                  SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                ]),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// AI 채팅(이미지 포함) 답변 완료 시 「오늘의 알림」 상단에 표시.
class _AiChatImageReplyHomeBanner extends StatelessWidget {
  const _AiChatImageReplyHomeBanner({
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.ctaLabel,
    required this.onOpenChat,
    required this.onDismiss,
  });

  final String title;
  final String preview;
  final String timeLabel;
  final String ctaLabel;
  final VoidCallback onOpenChat;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Link26ElevatedCard(
      child: InkWell(
        onTap: onOpenChat,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(Link26ResponsiveUi.gapMd(w)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: Link26ResponsiveUi.alarmAvatarRadius(w),
                backgroundColor: const Color(0xFFE8F5E9),
                child: Link26VectorIcons.chat(
                  const Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              SizedBox(width: Link26ResponsiveUi.alarmRowGap(w)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: Link26ResponsiveUi.bodySmall(w) + 1,
                              fontWeight: FontWeight.w900,
                              color: Link26Surface.textPrimary,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: Link26ResponsiveUi.caption(w),
                              fontWeight: FontWeight.w700,
                              color: Link26Surface.textMuted,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                    Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Link26ResponsiveUi.bodySmall(w),
                        height: 1.35,
                        color: Link26Surface.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                    Text(
                      ctaLabel,
                      style: TextStyle(
                        fontSize: Link26ResponsiveUi.caption(w),
                        fontWeight: FontWeight.w900,
                        color: Link26Surface.accent,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Link26VectorIcons.xMark(
                  Link26Surface.textMuted,
                  size: 22,
                ),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final r = Link26ResponsiveUi.searchPillRadius(w);
    final h = Link26ResponsiveUi.searchPillHeight(w);
    final pad = Link26ResponsiveUi.searchPillInlinePad(w);
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: Ink(
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: Link26Surface.outline),
          ),
          child: Row(
            children: [
              SizedBox(width: pad),
              Expanded(
                child: Text(
                  '약 이름, 성분, 복용 시간 등을 검색하세요',
                  style: TextStyle(
                    color: Link26Surface.textSecondary,
                    fontSize: Link26ResponsiveUi.searchHint(w),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: Link26ResponsiveUi.gapSm(w)),
              Link26VectorIcons.search(
                Link26Surface.textMuted,
                size: Link26ResponsiveUi.searchIconSize(w),
              ),
              SizedBox(width: pad),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Link26Surface.textMuted,
            fontSize: Link26ResponsiveUi.statLabel(w),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Link26ResponsiveUi.gapSm(w)),
        Text(
          value,
          style: TextStyle(
            color: Link26Surface.accent,
            fontSize: Link26ResponsiveUi.statValue(w),
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _AlarmPreviewCard extends StatelessWidget {
  const _AlarmPreviewCard({required this.item, required this.onDone});

  final AlarmItem item;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final avR = Link26ResponsiveUi.alarmAvatarRadius(w);
    return Link26ElevatedCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: avR,
            backgroundColor: const Color(0xFFEAF3FF),
            child: Link26VectorIcons.bell(
              Link26Surface.accent,
              size: avR * 1.15,
            ),
          ),
          SizedBox(width: Link26ResponsiveUi.alarmRowGap(w)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: Link26ResponsiveUi.alarmTime(w),
                        fontWeight: FontWeight.w800,
                        color: Link26Surface.textPrimary,
                      ),
                    ),
                    SizedBox(width: Link26ResponsiveUi.gapSm(w)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '알림',
                        style: TextStyle(
                          color: Link26Surface.accent,
                          fontSize: Link26ResponsiveUi.caption(w),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Link26ResponsiveUi.alarmMetaGap(w)),
                Text(
                  '${item.medicineName} ${item.dose}',
                  style: TextStyle(
                    color: Link26Surface.textSecondary,
                    fontSize: Link26ResponsiveUi.body(w),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: Link26Surface.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('복용 완료', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile({required this.item});

  final AlarmItem item;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(top: Link26ResponsiveUi.completedTileGapTop(w)),
      child: Link26ElevatedCard(
        padding: EdgeInsets.symmetric(
          horizontal: Link26ResponsiveUi.profileRowGap(w),
          vertical: Link26ResponsiveUi.gapSm(w) + Link26ResponsiveUi.gapXs(w),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: Link26ResponsiveUi.completedAvatarRadius(w),
              backgroundColor: const Color(0xFFEAF3FF),
              child: item.type == AlarmType.call
                  ? Link26VectorIcons.phone(
                      Link26Surface.accent,
                      size: Link26ResponsiveUi.completedAvatarRadius(w) * 1.9,
                    )
                  : Link26VectorIcons.bell(
                      Link26Surface.accent,
                      size: Link26ResponsiveUi.completedAvatarRadius(w) * 1.9,
                    ),
            ),
            SizedBox(width: Link26ResponsiveUi.gapMd(w)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.time} · ${item.type == AlarmType.call ? '전화' : '알림'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Link26Surface.textPrimary,
                      fontSize: Link26ResponsiveUi.completedRowTitle(w),
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapXs(w)),
                  Text(
                    '${item.medicineName} ${item.dose}',
                    style: TextStyle(
                      color: Link26Surface.textSecondary,
                      fontSize: Link26ResponsiveUi.bodySmall(w),
                    ),
                  ),
                ],
              ),
            ),
            Link26VectorIcons.check(
              Link26Surface.accent,
              size: Link26ResponsiveUi.searchIconSize(w) + Link26ResponsiveUi.gapXs(w),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(top: Link26ResponsiveUi.medicineTileGapTop(w)),
      child: Link26ElevatedCard(
        padding: EdgeInsets.symmetric(
          horizontal: Link26ResponsiveUi.profileRowGap(w),
          vertical: Link26ResponsiveUi.gapSm(w) + Link26ResponsiveUi.gapXs(w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: Link26ResponsiveUi.medicineAvatarRadius(w),
              backgroundColor: const Color(0xFFEAF3FF),
              child: Link26VectorIcons.capsule(
                Link26Surface.accent,
                size: Link26ResponsiveUi.medicineAvatarRadius(w) * 1.9,
              ),
            ),
            SizedBox(width: Link26ResponsiveUi.gapMd(w)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: Link26ResponsiveUi.medicineName(w),
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapXs(w)),
                  Text(
                    '${medicine.dose}   ${medicine.frequency}   ${medicine.time}',
                    style: TextStyle(
                      color: Link26Surface.textMuted,
                      fontSize: Link26ResponsiveUi.medicineMeta(w),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Link26VectorIcons.pencil(
                Link26Surface.accent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
