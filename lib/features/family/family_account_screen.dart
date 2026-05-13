import 'package:flutter/material.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';

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
  List<FamilyAccountRow> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    var list = <FamilyAccountRow>[];
    try {
      if (await AuthSession.isSignedIn()) {
        final user = await UserLocalRepository.loadSignedInUserRecord();
        if (user != null) {
          final name =
              UserLocalRepository.normalizeDisplayName(user.displayName);
          final label = name.isEmpty ? '(이름 없음) (나)' : '$name (나)';
          final phone =
              UserLocalRepository.formatPhoneDigitsForDisplay(user.phoneDigits);
          list = [
            FamilyAccountRow(label, '가족 관리자', phone),
          ];
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _members = list;
          _loading = false;
        });
      }
    }
  }

  void addMember() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('가족 구성원 추가·연동은 준비 중입니다.'),
      ),
    );
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
                  _loading
                      ? '…'
                      : '${_members.length}/5명',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_members.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  '로그인한 계정 정보가 없습니다. 더보기 상단 프로필이 본인인지 확인한 뒤, '
                  '본인이 아니면 로그아웃 후 다시 로그인·회원가입해 주세요.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: _members
                      .map(
                        (m) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEAF3FF),
                            child: Text(_initial(m.name)),
                          ),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text(
                            m.phone.isEmpty ? m.relation : '${m.relation} · ${m.phone}',
                          ),
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
                'ⓘ 가족 계정이란?\n\n'
                '가족 구성원의 건강 정보를 함께 관리하는 기능입니다. '
                '지금은 본인(로그인 계정)만 목록에 표시되며, '
                '다른 가족 연동은 추후 제공 예정입니다.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
