import 'package:flutter/material.dart';

import 'package:link26_app/core/services/dose_reminder_completion_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
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
      backgroundColor: Link26UnifiedPage.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    foregroundColor: Link26Surface.textPrimary,
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.06),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '전체 알림',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...chips.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: filter == c ? Colors.white : Link26Surface.textPrimary,
                          ),
                        ),
                        selected: filter == c,
                        onSelected: (_) => setState(() => filter = c),
                        selectedColor: Link26Surface.accent,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Link26Surface.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        showCheckmark: false,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Link26Surface.accent,
                      side: const BorderSide(color: Link26Surface.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: const Text('날짜 선택', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '2024년 5월 20일 (월)',
              style: TextStyle(
                color: Link26Surface.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ...filtered.map(
              (item) => _AlarmTile(
                item: item,
                onDone: () async {
                  await DoseReminderCompletionStore.markCompleted(
                    item.medicineName,
                  );
                  if (!mounted) return;
                  setState(() => item.completed = true);
                },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Link26ElevatedCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Link26Surface.chipTint,
              child: Icon(
                isCall ? Icons.call_outlined : Icons.notifications_none_rounded,
                color: Link26Surface.accent,
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
                          color: Link26Surface.badgeTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCall ? '전화' : '알림',
                          style: const TextStyle(
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
            if (item.completed)
              const Text(
                '✓ 완료',
                style: TextStyle(
                  color: Link26Surface.accent,
                  fontWeight: FontWeight.w900,
                ),
              )
            else
              FilledButton(
                onPressed: onDone,
                style: Link26Surface.filledAccentButton(),
                child: const Text('복용 완료', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
