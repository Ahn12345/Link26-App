import 'package:flutter/material.dart';

class FamilyAccountRow {
  FamilyAccountRow(this.name, this.relation, this.phone);

  final String name;
  final String relation;
  final String phone;
}

class FamilyAccountScreen extends StatefulWidget {
  const FamilyAccountScreen({super.key});

  @override
  State<FamilyAccountScreen> createState() => _FamilyAccountScreenState();
}

class _FamilyAccountScreenState extends State<FamilyAccountScreen> {
  final members = <FamilyAccountRow>[
    FamilyAccountRow('김건강 (나)', '가족 관리자', ''),
    FamilyAccountRow('이효자', '딸', '010-1234-5678'),
    FamilyAccountRow('박효자', '아들', '010-5678-1234'),
  ];

  void addMember() {
    if (members.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족 구성원은 최대 5명까지 추가할 수 있습니다.')),
      );
      return;
    }
    setState(() => members.add(FamilyAccountRow('새 가족 ${members.length + 1}', '가족', '010-0000-0000')));
  }

  String _initial(String name) {
    if (name.isEmpty) return '?';
    return String.fromCharCode(name.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                const Text('가족 계정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 12),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.group_outlined),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '가족 구성원\n최대 5명까지 가족 구성원을 관리할 수 있습니다.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Text('내 가족', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                Text(
                  '${members.length}/5명',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: members
                    .map(
                      (m) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEAF3FF),
                          child: Text(_initial(m.name)),
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text(m.phone.isEmpty ? m.relation : '${m.relation} · ${m.phone}'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: addMember,
                icon: const Icon(Icons.add),
                label: const Text('가족 구성원 추가 (최대 5명)'),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'ⓘ 가족 계정이란?\n\n가족 구성원의 건강 정보를 함께 관리하고 AI 채팅 상담을 이용할 수 있는 기능입니다.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
