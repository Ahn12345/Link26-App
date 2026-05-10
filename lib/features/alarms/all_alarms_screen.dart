import 'package:flutter/material.dart';

import 'package:link26_app/models/alarm_item.dart';

class AllAlarmsScreen extends StatefulWidget {
  const AllAlarmsScreen({super.key, required this.alarms});

  final List<AlarmItem> alarms;

  @override
  State<AllAlarmsScreen> createState() => _AllAlarmsScreenState();
}

class _AllAlarmsScreenState extends State<AllAlarmsScreen> {
  String filter = '전체';

  List<AlarmItem> get filtered {
    if (filter == '알림') {
      return widget.alarms.where((e) => e.type == AlarmType.app).toList();
    }
    if (filter == '전화') {
      return widget.alarms.where((e) => e.type == AlarmType.call).toList();
    }
    if (filter == '복용 완료') {
      return widget.alarms.where((e) => e.completed).toList();
    }
    return widget.alarms;
  }

  @override
  Widget build(BuildContext context) {
    const chips = ['전체', '알림', '전화', '복용 완료'];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                const Text('전체 알림', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ...chips.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: filter == c,
                      onSelected: (_) => setState(() => filter = c),
                      selectedColor: const Color(0xFF0B6BFF),
                      labelStyle: TextStyle(color: filter == c ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('날짜 선택'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '2024년 5월 20일 (월)',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...filtered.map(
              (item) => _AlarmTile(
                item: item,
                onDone: () => setState(() => item.completed = true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({required this.item, required this.onDone});

  final AlarmItem item;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isCall = item.type == AlarmType.call;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCall ? const Color(0xFF0B6BFF) : const Color(0xFF7C3AED),
            child: Icon(
              isCall ? Icons.call : Icons.notifications_none,
              color: Colors.white,
            ),
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
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCall ? '전화' : '알림',
                      style: TextStyle(
                        color: isCall ? const Color(0xFF0B6BFF) : const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.medicineName} ${item.dose}',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          if (item.completed)
            const Text('✓ 완료', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900))
          else
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
