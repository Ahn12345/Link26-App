import 'package:flutter/material.dart';

class FamilyAccountsScreen extends StatelessWidget {
  const FamilyAccountsScreen({super.key});

  static const members = [
    _Member('김건강 (나)', '가족 관리자', '김', Color(0xFF0B6BFF), true),
    _Member('이효자', '딸 · 010-1234-5678', '이', Color(0xFFFFD6E7), false),
    _Member('박효자', '아들 · 010-5678-1234', '박', Color(0xFFD8F6D9), false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(title: const Text('가족 계정'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Card(
            child: Row(
              children: const [
                CircleAvatar(radius: 28, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.groups_2_outlined, color: Color(0xFF64748B), size: 30)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가족 구성원', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text('최대 5명까지 가족 구성원을 관리할 수 있습니다.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(children: const [
            Expanded(child: Text('내 가족', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            Text('3/5명', style: TextStyle(fontSize: 18, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(children: members.map((m) => _MemberTile(member: m)).toList()),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('가족 구성원 추가 (최대 5명)', style: TextStyle(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              side: const BorderSide(color: Color(0xFF0B6BFF), width: 1.4),
              foregroundColor: const Color(0xFF0B6BFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 28),
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF64748B)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가족 계정이란?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Text('가족 구성원의 건강 정보를 함께 관리하고\nAI 채팅 상담을 이용할 수 있는 기능입니다.', style: TextStyle(color: Color(0xFF475569), height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});
  final _Member member;

  @override
  Widget build(BuildContext context) {
    final textColor = member.isMe ? Colors.white : const Color(0xFF111827);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundColor: member.color, child: Text(member.initial, style: TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w900))),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(member.subtitle, style: TextStyle(color: member.isMe ? const Color(0xFF0B6BFF) : const Color(0xFF64748B), fontWeight: member.isMe ? FontWeight.w800 : FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

class _Member {
  const _Member(this.name, this.subtitle, this.initial, this.color, this.isMe);
  final String name;
  final String subtitle;
  final String initial;
  final Color color;
  final bool isMe;
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: child,
      );
}
