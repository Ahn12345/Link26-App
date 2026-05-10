import 'package:flutter/material.dart';

import 'package:link26_app/features/alarms/all_alarms_screen.dart';
import 'package:link26_app/features/medicine/add_medicine_sheet.dart';
import 'package:link26_app/models/alarm_item.dart';
import 'package:link26_app/models/medicine.dart';

/// [MainShell] 홈 탭 — 카카오 functional `HomeScreen` 흐름(알림·바텀시트 약 추가).
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
  ];

  final List<AlarmItem> alarms = [
    AlarmItem(
      date: '2024년 5월 20일 (월)',
      time: '08:00',
      medicineName: '알로디핀',
      dose: '5mg',
      type: AlarmType.app,
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
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '건강한 하루를 시작하세요',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: '약 이름, 성분, 복용 시간 등을 검색하세요',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            child: Row(
              children: [
                Expanded(child: _Stat(title: '오늘 복용', value: '$completed/${alarms.length}')),
                Container(width: 1, height: 48, color: const Color(0xFFE2E8F0)),
                Expanded(child: _Stat(title: '등록된 약', value: '${medicines.length}개')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Header(
            title: '오늘의 알림',
            action: '전체보기',
            icon: Icons.calendar_month_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AllAlarmsScreen(alarms: alarms),
              ),
            ),
          ),
          _AlarmPreview(
            item: alarms.first,
            onDone: () => setState(() => alarms.first.completed = true),
          ),
          const SizedBox(height: 18),
          const Text('복용 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ...alarms.where((e) => e.completed).map((e) => _CompletedTile(item: e)),
          const SizedBox(height: 18),
          _Header(title: '내 약 목록', action: '+ 추가', onTap: _openAddMedicine),
          ...medicines.map((m) => _MedicineTile(medicine: m)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                '광고 배너 영역\n간단 보조 식품 추천',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E6FF)),
      ),
      child: child,
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
        Text(title, style: const TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0B6BFF),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.action,
    this.icon,
    this.onTap,
  });

  final String title;
  final String? action;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onTap,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
            label: Text(action!),
          ),
      ],
    );
  }
}

class _AlarmPreview extends StatelessWidget {
  const _AlarmPreview({required this.item, required this.onDone});

  final AlarmItem item;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF3FF),
            child: Icon(Icons.notifications_none, color: Color(0xFF0B6BFF)),
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
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    const Chip(label: Text('알림'), visualDensity: VisualDensity.compact),
                  ],
                ),
                Text('${item.medicineName} ${item.dose}', style: const TextStyle(color: Color(0xFF334155))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('복용 완료'),
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF3FF),
            child: Icon(
              item.type == AlarmType.call ? Icons.call : Icons.notifications_none,
              color: const Color(0xFF0B6BFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('${item.time}\n${item.medicineName} ${item.dose}')),
          const Icon(Icons.check, color: Color(0xFF10B981)),
        ],
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF3FF),
            child: Icon(Icons.medication_outlined, color: Color(0xFF0B6BFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${medicine.name}\n${medicine.dose}   ${medicine.frequency}   ${medicine.time}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0B6BFF)),
          ),
        ],
      ),
    );
  }
}
