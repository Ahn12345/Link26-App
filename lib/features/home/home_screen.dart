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
import 'package:link26_app/core/services/link26_bff_reachability.dart';
import 'package:link26_app/core/constants/app_build_fingerprint.dart';
import 'package:link26_app/core/constants/link26_medication_feature_flags.dart';
import 'package:link26_app/core/services/medication_list_display_prefs.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/services/medicine_list_loader.dart';
import 'package:link26_app/core/services/gemini_api_key_status.dart';
import 'package:link26_app/core/services/prescription_medicine_persistence.dart';
import 'package:link26_app/features/medicine/prescription_register_sheet.dart';
import 'package:link26_app/core/services/link26_bff_advice.dart';
import 'package:link26_app/core/services/link26_remote_bff_bootstrap.dart';
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
  bool _hideHospitalSupplies = false;

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
      _hideHospitalSupplies =
          await MedicationListDisplayPrefs.hideHospitalSupplies();
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
    final session = await AuthSession.activePhoneDigits();
    final sessionDigits = session?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (sessionDigits.length >= 10) return sessionDigits;
    final u = await UserLocalRepository.loadSignedInUserRecord();
    if (u != null) {
      final fromUser = u.phoneDigits.replaceAll(RegExp(r'\D'), '');
      if (fromUser.length >= 10) return fromUser;
    }
    return await UserLocalRepository.singleUserPhoneDigits() ?? '';
  }

  Future<void> _bootstrapMedicines() async {
    await _reloadMedicinesFromStores();
    if (!mounted) return;

    // 이전 부팅의 「전화번호…」 등 system_sync 알림이 홈에 남지 않게.
    await HomeNotificationRepository.clearSystemSyncNotices();

    final bffAdvice = Link26BffAdvice.takePendingNoticeKo();
    final previewParts = <String>[];
    if (bffAdvice != null && bffAdvice.isNotEmpty) {
      previewParts.add(bffAdvice);
    }

    if (!Link26MedicationFeatureFlags.tilkoHiraRemoteSyncEnabled) {
      if (kDebugMode) {
        debugPrint('NHIS: tilko/HIRA remote sync disabled — prescription register only');
      }
      if (mounted) await _reloadMedicinesFromStores();
      return;
    }

    final shouldSync =
        NhisRuntimeConfig.useMock || NhisRuntimeConfig.baseUrl.isNotEmpty;
    if (!shouldSync) {
      if (kDebugMode) {
        debugPrint(
          'NHIS: mock 꺼짐 + BFF 베이스 URL 비어 있음 — 복약 동기화 생략 '
          '(릴리스: NHIS_PRODUCTION_BASE_URL 또는 LINK26_REMOTE_CONFIG_URL JSON, '
          '디버그·프로파일: NHIS_BASE_URL)',
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
                  '릴리스에는 다음 중 하나가 필요합니다: '
                  '① dotenv에 LINK26_REMOTE_CONFIG_URL=https://…/manifest.json '
                  '(JSON에 nhisBffBases) ② 빌드 시 '
                  '--dart-define=NHIS_PRODUCTION_BASE_URL=https://… '
                  '(dotenv의 NHIS_BASE_URL은 릴리스에서 사용하지 않습니다.)',
        );
      }
      if (mounted && previewParts.isNotEmpty) {
        await HomeNotificationRepository.insertSystemSyncNotice(
          title: AppLocalizations.of(context).homeNotificationSystemSyncTitle,
          preview: previewParts.join('\n\n'),
        );
        await _refreshBellBadge();
      }
      if (mounted) await _reloadMedicinesFromStores();
      return;
    }

    // 실복약은 「심평원에서 불러오기」만. GET /v1/medications 스텁은 부팅 시 생략.
    final medsPath = NhisRuntimeConfig.medicinesPath;
    final stubMedsOnly = medsPath == '/v1/medications' ||
        medsPath.endsWith('/v1/medications');
    if (!stubMedsOnly) {
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
    } else if (kDebugMode) {
      debugPrint(
        'NHIS: 홈 부팅 — GET $medsPath 스텁 동기화 생략 (심평원에서 불러오기 사용)',
      );
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
    final merged = await MedicineListLoader.loadMerged(
      hideHospitalSupplies: _hideHospitalSupplies,
    );
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
    if (!Link26MedicationFeatureFlags.tilkoHiraRemoteSyncEnabled) {
      if (mounted) await _reloadMedicinesFromStores();
      return;
    }
    await NhisRuntimeConfig.refreshBffReachability();
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
    if (!Link26MedicationFeatureFlags.tilkoHiraRemoteSyncEnabled) {
      await _openPrescriptionRegister(openCamera: true);
      return;
    }
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
    await HomeNotificationRepository.markAllSystemSyncRead();
    Link26BffReachability.clearProbeCache();
    await NhisRuntimeConfig.refreshBffReachability();
    if (!mounted) return;
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
    final out = await HiraLinkService.promptRrnAndSyncHiraMedications(
      context: context,
      user: user,
      announceSuccess: false,
    );
    if (!mounted) return;
    await _reloadMedicinesFromStores();
    if (!mounted) return;
    if (out == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연동을 취소했거나 중단되었습니다.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    if (out.result == NhisMedicinesSyncResult.failed) {
      final msg = out.userMessageKo.trim();
      if (msg.isNotEmpty) {
        final kept = medicines.length;
        final text = kept > 0 &&
                (msg.contains('투약이력 조회에 실패') ||
                    msg.contains('LoginCheck'))
            ? '방금 올해 처방 다시 받기는 실패했습니다. '
                '기존 복약 $kept건은 그대로 두었습니다. '
                'PC에서 BFF를 재시작한 뒤 「심평원에서 불러오기」를 다시 눌러 주세요.'
            : msg;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 10)),
        );
      }
      return;
    }
    if (out.result == NhisMedicinesSyncResult.skipped) {
      final msg = out.userMessageKo.trim();
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
        );
      }
      return;
    }
    if (out.remoteItemCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.homeHiraMedicationsLoadSuccess} (${out.remoteItemCount}건)',
          ),
          action: SnackBarAction(
            label: '처방전 등록',
            onPressed: () => unawaited(_openPrescriptionRegister()),
          ),
          duration: const Duration(seconds: 12),
        ),
      );
    } else if (out.result == NhisMedicinesSyncResult.success) {
      final msg = out.userMessageKo.trim();
      if (out.remoteItemCount == 0 && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
        );
      } else if (out.remoteItemCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '연동은 완료됐지만 조회된 약이 없습니다. '
              'PASS 승인·조회 기간을 확인하거나 BFF 로그를 확인하세요.',
            ),
            duration: Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _quickAddMedicineByName() async {
    if (!mounted) return;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('약 이름 등록'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: Link26Surface.inputDecoration(
            labelText: '약 이름',
            hintText: '예: 케피람정 100mg',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: Link26UnifiedPage.filledCtaButton(),
            child: const Text('등록'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    final med = PrescriptionMedicinePersistence.stub(name);
    await PrescriptionMedicinePersistence.saveAll([med]);
    if (!mounted) return;
    await _reloadMedicinesFromStores();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$name」을 내 복약 목록에 등록했습니다.')),
    );
  }

  Future<void> _openPrescriptionRegister({bool openCamera = false}) async {
    if (!mounted) return;
    var useCamera = openCamera;
    var focusManual = false;
    if (openCamera) {
      final issue = await GeminiApiKeyStatus.checkBlockingIssueKo();
      if (issue != null) {
        useCamera = false;
        focusManual = true;
      }
    }
    if (!mounted) return;
    final added = await showModalBottomSheet<List<Medicine>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrescriptionRegisterSheet(
        openCameraOnStart: useCamera,
        focusManualFirst: focusManual,
      ),
    );
    if (added == null || added.isEmpty) return;
    await PrescriptionMedicinePersistence.saveAll(added);
    if (!mounted) return;
    await _reloadMedicinesFromStores();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('처방전 등록 ${added.length}건을 내 복약 목록에 반영했습니다.'),
      ),
    );
  }

  Future<void> _toggleHideHospitalSupplies(bool value) async {
    await MedicationListDisplayPrefs.setHideHospitalSupplies(value);
    if (!mounted) return;
    setState(() => _hideHospitalSupplies = value);
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
                  Text(
                    '빌드 $kAppBuildNumber · $kAppBuildTag',
                    style: TextStyle(
                      fontSize: Link26ResponsiveUi.caption(w),
                      color: Link26Surface.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          unawaited(_openPrescriptionRegister(openCamera: true)),
                      style: Link26UnifiedPage.filledCtaButton(),
                      icon: const Icon(Icons.photo_camera_outlined, size: 22),
                      label: const Text(
                        '처방전 촬영 등록',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(_quickAddMedicineByName()),
                      icon: const Icon(Icons.medication_outlined, size: 22),
                      label: const Text(
                        '약 이름으로 바로 등록',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (!Link26MedicationFeatureFlags.tilkoHiraRemoteSyncEnabled)
                    Padding(
                      padding: EdgeInsets.only(top: Link26ResponsiveUi.gapSm(w)),
                      child: Text(
                        '심평원 자동 불러오기는 잠시 꺼 두었습니다. '
                        '사진 인식은 API 키 설정 후 가능합니다. 지금은 「약 이름으로 바로 등록」을 이용해 주세요.',
                        style: TextStyle(
                          color: Link26Surface.textMuted,
                          fontSize: Link26ResponsiveUi.caption(w),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  if (medicines.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Link26ResponsiveUi.gapSm(w),
                      ),
                      child: FilterChip(
                        label: const Text('복용 약만 보기'),
                        selected: _hideHospitalSupplies,
                        onSelected: (v) => unawaited(_toggleHideHospitalSupplies(v)),
                      ),
                    ),
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
                            '위 「처방전 촬영 등록」으로 약을 추가하세요.',
                            style: TextStyle(
                              color: Link26Surface.textMuted,
                              fontSize: Link26ResponsiveUi.bodySmall(w),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (Link26MedicationFeatureFlags
                              .tilkoHiraRemoteSyncEnabled) ...[
                            if (!NhisRuntimeConfig.useMock) ...[
                              SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                              FilledButton.tonal(
                                onPressed: () => unawaited(
                                  _importHiraMedicationsFromHome(),
                                ),
                                child: Text(l10n.homeHiraMedicationsImport),
                              ),
                            ],
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
                    Flexible(
                      child: Text(
                        item.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Link26ResponsiveUi.alarmTime(w),
                          fontWeight: FontWeight.w800,
                          color: Link26Surface.textPrimary,
                        ),
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
                  '${item.medicineName} ${item.dose}'.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Link26Surface.textSecondary,
                    fontSize: Link26ResponsiveUi.body(w),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Link26ResponsiveUi.gapSm(w).clamp(6.0, 10.0)),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: Link26Surface.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              '복용 완료',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: Link26ResponsiveUi.caption(w).clamp(11.0, 13.0),
              ),
            ),
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
