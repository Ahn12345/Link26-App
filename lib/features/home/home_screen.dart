import 'package:flutter/material.dart';

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
  final List<Medicine> medicines = [
    const Medicine(
      name: '아스피린 (Aspirin)',
      dose: '100mg',
      frequency: '1일 1회',
      time: '08:00',
    ),
    const Medicine(
      name: '메트프로민 (Metformin)',
      dose: '500mg',
      frequency: '1일 2회',
      time: '08:00',
    ),
    const Medicine(
      name: '오메프라졸 (Omeprazole)',
      dose: '20mg',
      frequency: '1일 1회',
      time: '09:00',
    ),
  ];

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

  Future<void> _openAddMedicine() async {
    final result = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicineSheet(),
    );
    if (result != null) setState(() => medicines.add(result));
  }

  @override
  Widget build(BuildContext context) {
    final completed = alarms.where((e) => e.completed).length;
    // [MainShell] extendBody: true 이면 본문이 하단 네비 뒤로 깔리므로 여백을 둡니다.
    final bottomPad =
        MediaQuery.of(context).padding.bottom + 88;

    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 28 + bottomPad),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          '건강한 하루를 시작하세요',
                          style: TextStyle(
                            fontSize: 24,
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
                  const SizedBox(height: 14),
                  _SearchPill(
                    onTap: () =>
                        Navigator.of(context).pushNamed(PillSearchScreen.routeName),
                  ),
                  const SizedBox(height: 20),
                  Link26ElevatedCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            title: '오늘 복용',
                            value: '$completed/${alarms.length}',
                          ),
                        ),
                        Container(width: 1, height: 54, color: Link26Surface.outline),
                        Expanded(
                          child: _Stat(
                            title: '등록된 약',
                            value: '${medicines.length}개',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 8),
                  _AlarmPreviewCard(
                    item: alarms.first,
                    onDone: () => setState(() => alarms.first.completed = true),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '복용 완료',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...alarms
                      .where((e) => e.completed)
                      .map((e) => _CompletedTile(item: e)),
                  const SizedBox(height: 18),
                  Link26SectionHeader(
                    title: '내 약 목록',
                    action: '+ 추가',
                    onAction: _openAddMedicine,
                  ),
                  const SizedBox(height: 8),
                  ...medicines.map((m) => _MedicineTile(medicine: m)),
                  const SizedBox(height: 12),
                  const _AdBanner(),
                ]),
              ),
            ),
          ],
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
    const r = 30.0;
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: Link26Surface.outline),
          ),
          child: Row(
            children: [
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  '약 이름, 성분, 복용 시간 등을 검색하세요',
                  style: TextStyle(
                    color: Link26Surface.textSecondary,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.search_rounded, color: Link26Surface.textMuted, size: 26),
              SizedBox(width: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Link26Surface.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Link26Surface.accent,
            fontSize: 30,
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
    return Link26ElevatedCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEAF3FF),
            child: Icon(Icons.notifications_none_rounded, color: Link26Surface.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Link26Surface.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '알림',
                        style: TextStyle(
                          color: Link26Surface.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.medicineName} ${item.dose}',
                  style: const TextStyle(
                    color: Link26Surface.textSecondary,
                    fontSize: 15,
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
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Link26ElevatedCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEAF3FF),
              child: Icon(
                item.type == AlarmType.call ? Icons.call_outlined : Icons.notifications_none_rounded,
                color: Link26Surface.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.time} · ${item.type == AlarmType.call ? '전화' : '알림'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.medicineName} ${item.dose}',
                    style: const TextStyle(color: Link26Surface.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Link26Surface.accent, size: 28),
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
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Link26ElevatedCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFEAF3FF),
              child: Icon(Icons.medication_outlined, color: Link26Surface.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medicine.dose}   ${medicine.frequency}   ${medicine.time}',
                    style: const TextStyle(
                      color: Link26Surface.textMuted,
                      fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
      child: const Center(
        child: Text(
          '광고 배너 영역\n간단 보조 식품 추천',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }
}
