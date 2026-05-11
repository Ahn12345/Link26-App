import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/features/alarms/all_alarms_screen.dart';
import 'package:link26_app/features/medicine/add_medicine_sheet.dart';
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

  String _normMedName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  final List<AlarmItem> alarms = [
    AlarmItem(
      date: '2024년 5월 20일 (월)',
      time: '08:00',
      medicineName: '알로디핀',
      dose: '5mg',
      type: AlarmType.app,
      completed: false,
    ),
    AlarmItem(
      date: '2024년 5월 20일 (월)',
      time: '08:00',
      medicineName: '아스피린',
      dose: '100mg',
      type: AlarmType.call,
      completed: true,
    ),
    AlarmItem(
      date: '2024년 5월 20일 (월)',
      time: '08:00',
      medicineName: '메트프로민',
      dose: '500mg',
      type: AlarmType.app,
      completed: true,
    ),
    AlarmItem(
      date: '2024년 5월 20일 (월)',
      time: '12:00',
      medicineName: '비타민 D',
      dose: '1000IU',
      type: AlarmType.app,
      completed: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapMedicines());
  }

  /// 세션 전화가 없어도, 로그인 상태이고 로컬 사용자가 한 명이면 DB 전화로 BFF 동기화.
  Future<String> _phoneForNhisSync() async {
    final session = await AuthSession.activePhoneDigits();
    if (session != null && session.isNotEmpty) return session;
    if (!await AuthSession.isSignedIn()) return '';
    final single = await UserLocalRepository.singleUserPhoneDigits();
    return single ?? '';
  }

  Future<void> _bootstrapMedicines() async {
    await _reloadMedicinesFromStores();
    if (!mounted) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    final shouldSync =
        NhisRuntimeConfig.useMock || NhisRuntimeConfig.baseUrl.isNotEmpty;
    if (!shouldSync) {
      if (kDebugMode) {
        debugPrint(
          'NHIS: mock 꺼짐 + NHIS_BASE_URL 비어 있음 — 복약 동기화 생략',
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(syncOut.userMessageKo),
          duration: const Duration(seconds: 6),
        ),
      );
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
    if (mounted) setState(() => medicines = merged);
  }

  Future<void> _refreshMedicinesFromServer() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
    final shouldSync =
        NhisRuntimeConfig.useMock || NhisRuntimeConfig.baseUrl.isNotEmpty;
    if (shouldSync) {
      final phone = await _phoneForNhisSync();
      final syncOut = await NhisMedicinesSync.syncNow(phoneDigits: phone);
      if (mounted) await _reloadMedicinesFromStores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncOut.userMessageKo),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      if (mounted) await _reloadMedicinesFromStores();
    }
  }

  Future<void> _openAddMedicine() async {
    final result = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicineSheet(),
    );
    if (result == null) return;
    await LocalMedicineListStore.add(result.name);
    await NhisMedicineCacheStore.upsert(result);
    await _reloadMedicinesFromStores();
  }

  @override
  Widget build(BuildContext context) {
    final completed = alarms.where((e) => e.completed).length;
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
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: Link26Surface.textSecondary,
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
                            value: '$completed/${alarms.length}',
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
                    icon: Icons.calendar_month_outlined,
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AllAlarmsScreen(alarms: alarms),
                      ),
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  _AlarmPreviewCard(
                    item: alarms.first,
                    onDone: () => setState(() => alarms.first.completed = true),
                  ),
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
                  ...alarms
                      .where((e) => e.completed)
                      .map((e) => _CompletedTile(item: e)),
                  SizedBox(height: Link26ResponsiveUi.gapLg(w)),
                  Link26SectionHeader(
                    title: '내 약 목록',
                    action: '+ 추가',
                    onAction: _openAddMedicine,
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  if (medicines.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: Link26ResponsiveUi.gapMd(w),
                        bottom: Link26ResponsiveUi.gapSm(w),
                      ),
                      child: Text(
                        '검색·동기화로 약을 추가해 보세요',
                        style: TextStyle(
                          color: Link26Surface.textMuted,
                          fontSize: Link26ResponsiveUi.bodySmall(w),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ...medicines.map((m) => _MedicineTile(medicine: m)),
                  SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                  const _AdBanner(),
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
              Icon(
                Icons.search_rounded,
                color: Link26Surface.textMuted,
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
            child: const Icon(Icons.notifications_none_rounded, color: Link26Surface.accent),
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
              child: Icon(
                item.type == AlarmType.call ? Icons.call_outlined : Icons.notifications_none_rounded,
                color: Link26Surface.accent,
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
            Icon(
              Icons.check_circle,
              color: Link26Surface.accent,
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
              child: const Icon(Icons.medication_outlined, color: Link26Surface.accent),
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
              icon: const Icon(Icons.edit_outlined, color: Link26Surface.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Link26ResponsiveUi.adBannerPadH(w),
        vertical: Link26ResponsiveUi.adBannerPadV(w),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8F1FF),
            Link26Surface.accent.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E4FF)),
        boxShadow: [
          BoxShadow(
            color: Link26Surface.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '광고 배너 영역\n간단 보조 식품 추천',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Link26ResponsiveUi.adBannerText(w),
            height: 1.45,
            color: const Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }
}
