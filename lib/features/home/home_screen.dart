import 'package:flutter/material.dart';
import 'package:link26_app/models/link_models.dart';

import '../../core/services/local_medicine_list_store.dart';
import '../search/pill_search_screen.dart';

/// 홈 대시보드 색·그림자 (목업 / 고퀄 카드 UI)
abstract final class _HomeDashTokens {
  static const surface = Color(0xFFFFFFFF);
  static const outlineSoft = Color(0xFFE8EEF5);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const accentBlue = Color(0xFF0B6BFF);
}

/// [MainShell] 홈 탭 본문 — 우측 목업과 같은 대시보드(검색·요약·알림·복용완료·내 약·배너).
class HomeDashboardContent extends StatefulWidget {
  const HomeDashboardContent({super.key});

  @override
  State<HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<HomeDashboardContent> {
  List<String> _registeredNames = [];

  static const _demoMedicines = [
    Medication(id: '1', name: '아스피린', englishName: 'Aspirin', dose: '100mg', frequency: '1일 1회', time: '08:00', completed: true),
    Medication(id: '2', name: '메트포르민', englishName: 'Metformin', dose: '500mg', frequency: '1일 2회', time: '08:00', completed: true),
    Medication(id: '3', name: '알로디핀', englishName: 'Amlodipine', dose: '5mg', frequency: '1일 1회', time: '08:00'),
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final names = await LocalMedicineListStore.load();
    if (mounted) setState(() => _registeredNames = names);
  }

  Future<void> _openPillSearch() async {
    await Navigator.of(context).pushNamed(PillSearchScreen.routeName);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final registeredCount =
        _registeredNames.isNotEmpty ? _registeredNames.length : _demoMedicines.length;

    final listTiles = <Widget>[
      if (_registeredNames.isNotEmpty)
        ..._registeredNames.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RegisteredMedicineTile(name: name),
          ),
        )
      else
        ..._demoMedicines
            .take(2)
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MedicineTile(medicine: m),
              ),
            ),
    ];

    return ColoredBox(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '건강한 하루를 시작하세요',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        color: _HomeDashTokens.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Material(
                    color: _HomeDashTokens.surface,
                    shape: const CircleBorder(),
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.06),
                    child: IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AlarmListScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: _HomeDashTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SearchBox(onTap: _openPillSearch),
              const SizedBox(height: 20),
              _SummaryCard(registeredCount: registeredCount),
              const SizedBox(height: 18),
              _SectionTitle(
                title: '오늘의 알림',
                action: '전체보기',
                icon: Icons.calendar_month_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AlarmListScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _TodayAlarmCard(),
              const SizedBox(height: 18),
              const _SectionTitle(title: '복용 완료'),
              const SizedBox(height: 10),
              _CompletedCard(
                medicines: _demoMedicines.where((e) => e.completed).toList(),
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: '내 약 목록',
                action: '+ 추가',
                onTap: _openPillSearch,
              ),
              const SizedBox(height: 10),
              ...listTiles,
              const _BannerCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    const radius = 32.0;
    return Material(
      color: _HomeDashTokens.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _HomeDashTokens.outlineSoft, width: 1),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '약 이름, 성분, 복용 시간 등을 검색하세요',
                    style: TextStyle(
                      color: _HomeDashTokens.textSecondary,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
                Icon(Icons.search_rounded, size: 26, color: _HomeDashTokens.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.registeredCount});

  final int registeredCount;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          '오늘 복용 & 등록된 약',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _HomeDashTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: _Metric(label: '오늘 복용', value: '3/4')),
          const SizedBox(height: 52, child: VerticalDivider()),
          Expanded(
            child: _Metric(label: '등록된 약', value: '$registeredCount개'),
          ),
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _HomeDashTokens.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _HomeDashTokens.accentBlue,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
}

class _TodayAlarmCard extends StatelessWidget {
  const _TodayAlarmCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(children: [
        const _RoundIcon(icon: Icons.notifications_none, color: Color(0xFF0B6BFF), soft: Color(0xFFEAF2FF)),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '08:00',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _HomeDashTokens.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  _Pill('알림'),
                ],
              ),
              SizedBox(height: 6),
              Text(
                '알로디핀 5mg',
                style: TextStyle(
                  color: _HomeDashTokens.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: _HomeDashTokens.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '복용 완료',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '08:00',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _HomeDashTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Pill(type),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  color: _HomeDashTokens.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${medicine.name} (${medicine.englishName})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _HomeDashTokens.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${medicine.dose}   ${medicine.frequency}   ${medicine.time}',
                style: const TextStyle(
                  color: _HomeDashTokens.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.medication, color: Color(0xFF0B6BFF), size: 26),
      ]),
    );
  }
}

class _RegisteredMedicineTile extends StatelessWidget {
  const _RegisteredMedicineTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const _RoundIcon(
            icon: Icons.medication_outlined,
            color: Color(0xFF0B6BFF),
            soft: Color(0xFFEAF2FF),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _HomeDashTokens.textPrimary,
                  ),
                ),
                Text(
                  '등록됨 · 상세는 검색에서 추가·수정',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.medication, color: Color(0xFF0B6BFF), size: 26),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7E4FF)),
          boxShadow: [
            BoxShadow(
              color: _HomeDashTokens.accentBlue.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          '광고 배너 영역\n간단 보조 식품 추천',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.45,
          ),
        ),
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
    MedicineAlarm(id: '1', dateLabel: '2024년 5월 20일 (월)', time: '08:00', type: '알림', medicineName: '알로디핀', dose: '5mg', status: '복용 완료'),
    MedicineAlarm(id: '2', dateLabel: '2024년 5월 20일 (월)', time: '08:00', type: '전화', medicineName: '아스피린', dose: '100mg', status: '완료'),
    MedicineAlarm(id: '3', dateLabel: '2024년 5월 20일 (월)', time: '12:00', type: '전화', medicineName: '비타민D', dose: '1000IU', status: '예정'),
    MedicineAlarm(id: '4', dateLabel: '2024년 5월 20일 (월)', time: '20:00', type: '알림', medicineName: '메트포르민', dose: '500mg', status: '복용 완료'),
    MedicineAlarm(id: '5', dateLabel: '2024년 5월 19일 (일)', time: '08:00', type: '알림', medicineName: '알로디핀', dose: '5mg', status: '완료'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.icon, this.onTap});
  final String title;
  final String? action;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _HomeDashTokens.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (action != null)
            TextButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18, color: _HomeDashTokens.accentBlue),
              label: Text(
                action!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _HomeDashTokens.accentBlue,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _HomeDashTokens.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _HomeDashTokens.outlineSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: _HomeDashTokens.accentBlue.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: _HomeDashTokens.accentBlue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      );
}
