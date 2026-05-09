import 'package:flutter/material.dart';
import 'package:link26_app/models/link_models.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [
    _HomeTab(),
    AiChatScreen(showScaffold: false),
    MoreScreen(showScaffold: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'AI 채팅'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  static const medicines = [
    Medication(id: '1', name: '아스피린', englishName: 'Aspirin', dose: '100mg', frequency: '1일 1회', time: '08:00', completed: true),
    Medication(id: '2', name: '메트포르민', englishName: 'Metformin', dose: '500mg', frequency: '1일 2회', time: '08:00', completed: true),
    Medication(id: '3', name: '암로디핀', englishName: 'Amlodipine', dose: '5mg', frequency: '1일 1회', time: '08:00'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('건강한 하루를 시작하세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmListScreen())), icon: const Icon(Icons.notifications_none)),
            ],
          ),
          const SizedBox(height: 14),
          _SearchBox(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreenMock()))),
          const SizedBox(height: 20),
          _SummaryCard(),
          const SizedBox(height: 18),
          _SectionTitle(title: '오늘의 알림', action: '전체보기', icon: Icons.calendar_month_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmListScreen()))),
          const SizedBox(height: 10),
          _TodayAlarmCard(),
          const SizedBox(height: 18),
          const _SectionTitle(title: '복용 완료'),
          const SizedBox(height: 10),
          _CompletedCard(medicines: medicines.where((e) => e.completed).toList()),
          const SizedBox(height: 18),
          _SectionTitle(title: '내 약 목록', action: '+ 추가', onTap: () => _showAddMedicineSheet(context)),
          const SizedBox(height: 10),
          ...medicines.take(2).map((m) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _MedicineTile(medicine: m))),
          const _BannerCard(),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4)),
        child: const Row(children: [Expanded(child: Text('약 이름, 성분, 복용 시간 등을 검색하세요', style: TextStyle(color: Color(0xFF475569)))), Icon(Icons.search, size: 28)]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('오늘 복용 & 등록된 약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(children: const [
          Expanded(child: _Metric(label: '오늘 복용', value: '3/4')),
          SizedBox(height: 52, child: VerticalDivider()),
          Expanded(child: _Metric(label: '등록된 약', value: '3개')),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 15)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Color(0xFF0B6BFF), fontSize: 30, fontWeight: FontWeight.w900)),
      ]);
}

class _TodayAlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(children: [
        const _RoundIcon(icon: Icons.notifications_none, color: Color(0xFF0B6BFF), soft: Color(0xFFEAF2FF)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('08:00', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(width: 8), _Pill('알림')]),
          SizedBox(height: 4), Text('암로디핀 5mg', style: TextStyle(color: Color(0xFF334155), fontSize: 16)),
        ])),
        FilledButton(onPressed: () {}, child: const Text('복용 완료')),
      ]),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.medicines});
  final List<Medication> medicines;
  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(children: medicines.map((m) => _AlarmMiniTile(name: '${m.name} ${m.dose}', type: m.id == '1' ? '전화' : '알림')).toList()),
    );
  }
}

class _AlarmMiniTile extends StatelessWidget {
  const _AlarmMiniTile({required this.name, required this.type});
  final String name;
  final String type;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(children: [
        _RoundIcon(icon: type == '전화' ? Icons.call_outlined : Icons.notifications_none, color: const Color(0xFF0B6BFF), soft: const Color(0xFFEAF2FF)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('08:00', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(width: 8), _Pill(type)]), const SizedBox(height: 4), Text(name, style: const TextStyle(color: Color(0xFF334155), fontSize: 16))])),
        const Icon(Icons.check, color: Color(0xFF0B6BFF), size: 30),
      ]),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({required this.medicine});
  final Medication medicine;
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(children: [
        const _RoundIcon(icon: Icons.medication_outlined, color: Color(0xFF0B6BFF), soft: Color(0xFFEAF2FF)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${medicine.name} (${medicine.englishName})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text('${medicine.dose}   ${medicine.frequency}   ${medicine.time}', style: const TextStyle(color: Color(0xFF475569), fontSize: 15))])),
        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, color: Color(0xFF0B6BFF))),
      ]),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(18),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD7E4FF))),
        child: const Text('광고 배너 영역\n간단 보조 식품 추천', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700)),
      );
}

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});
  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  String filter = '전체';
  final items = const [
    MedicineAlarm(id: '1', dateLabel: '2024년 5월 20일 (월)', time: '08:00', type: '알림', medicineName: '암로디핀', dose: '5mg', status: '복용 완료'),
    MedicineAlarm(id: '2', dateLabel: '2024년 5월 20일 (월)', time: '08:00', type: '전화', medicineName: '아스피린', dose: '100mg', status: '완료'),
    MedicineAlarm(id: '3', dateLabel: '2024년 5월 20일 (월)', time: '12:00', type: '전화', medicineName: '비타민D', dose: '1000IU', status: '예정'),
    MedicineAlarm(id: '4', dateLabel: '2024년 5월 20일 (월)', time: '20:00', type: '알림', medicineName: '메트포르민', dose: '500mg', status: '복용 완료'),
    MedicineAlarm(id: '5', dateLabel: '2024년 5월 19일 (일)', time: '08:00', type: '알림', medicineName: '암로디핀', dose: '5mg', status: '완료'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((e) => filter == '전체' || e.type == filter || e.status == filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('전체 알림')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...['전체', '알림', '전화', '복용 완료'].map(
              (f) => ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 18),
              label: const Text('날짜 선택'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 22),
        for (final date in filtered.map((e) => e.dateLabel).toSet()) ...[
          Text(date, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          ...filtered.where((e) => e.dateLabel == date).map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _AlarmListTile(item: e))),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

class _AlarmListTile extends StatelessWidget {
  const _AlarmListTile({required this.item});
  final MedicineAlarm item;
  @override
  Widget build(BuildContext context) {
    final isCall = item.type == '전화';
    final done = item.status.contains('완료');
    return _Card(
      child: Row(children: [
        _RoundIcon(icon: isCall ? Icons.call_outlined : Icons.notifications, color: isCall ? const Color(0xFF0B6BFF) : const Color(0xFF7C3AED), soft: isCall ? const Color(0xFFEAF2FF) : const Color(0xFFF3E8FF)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(item.time, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(width: 8), _Pill(item.type)]), const SizedBox(height: 5), Text('${item.medicineName} ${item.dose}', style: const TextStyle(fontSize: 16, color: Color(0xFF475569)))])),
        done ? const Text('✓ 완료', style: TextStyle(color: Color(0xFF00B83F), fontWeight: FontWeight.w800)) : Text(item.status, style: const TextStyle(color: Color(0xFF475569))),
      ]),
    );
  }
}

class SearchScreenMock extends StatelessWidget {
  const SearchScreenMock({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('약 검색')), body: const Padding(padding: EdgeInsets.all(20), child: Column(children: [_SearchBox(), SizedBox(height: 24), _MedicineTile(medicine: Medication(id: '1', name: '아스피린', englishName: 'Aspirin', dose: '100mg', frequency: '1일 1회', time: '08:00'))])));
}


void _showAddMedicineSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AddMedicineSheet(),
  );
}

class _AddMedicineSheet extends StatelessWidget {
  const _AddMedicineSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('약 추가', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 32)),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                decoration: InputDecoration(
                  hintText: '약 이름 검색',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 24),
              const _MedicineSuggestion(index: 1, name: '타이레놀'),
              const SizedBox(height: 14),
              const _MedicineSuggestion(index: 2, name: '아모잘탄'),
              const SizedBox(height: 24),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                child: Row(
                  children: const [
                    Expanded(child: Text('직접 입력', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    Icon(Icons.arrow_forward, color: Color(0xFF94A3B8), size: 30),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('완료', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineSuggestion extends StatelessWidget {
  const _MedicineSuggestion({required this.index, required this.name});
  final int index;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF1F5F9), child: Text('$index', style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800))),
          const SizedBox(width: 16),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          const Icon(Icons.info_outline, color: Color(0xFF94A3B8)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('추가'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF111827), side: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.icon, this.onTap});
  final String title;
  final String? action;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), if (action != null) TextButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(action!))]);
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, required this.soft});
  final IconData icon;
  final Color color;
  final Color soft;
  @override
  Widget build(BuildContext context) => CircleAvatar(backgroundColor: soft, radius: 23, child: Icon(icon, color: color));
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(6)), child: Text(text, style: const TextStyle(color: Color(0xFF0B6BFF), fontSize: 12, fontWeight: FontWeight.w800)));
}
