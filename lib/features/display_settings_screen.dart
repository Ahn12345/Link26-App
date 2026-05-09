import 'package:flutter/material.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  double textScale = 1.0;
  bool boldText = true;
  bool highContrast = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(title: const Text('표시 설정'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text('글자 크기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('앱 전체의 글자 크기를 조절할 수 있습니다.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 22),
          _Card(
            child: Row(
              children: const [
                CircleAvatar(radius: 34, backgroundColor: Color(0xFF0B6BFF), child: Text('김', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.w900))),
                SizedBox(width: 18),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('김건강', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('kimhealth@example.com', style: TextStyle(color: Color(0xFF64748B), fontSize: 16))])),
                Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('작게', style: TextStyle(fontWeight: FontWeight.w700)), Text('크게', style: TextStyle(fontWeight: FontWeight.w700))]),
          Slider(
            min: .8,
            max: 1.3,
            divisions: 4,
            value: textScale,
            label: textScale == 1.0 ? '보통' : textScale < 1.0 ? '작게' : '크게',
            onChanged: (v) => setState(() => textScale = v),
          ),
          Center(child: Text(textScale == 1.0 ? '보통' : textScale < 1.0 ? '작게' : '크게', style: const TextStyle(color: Color(0xFF0B6BFF), fontWeight: FontWeight.w800))),
          const SizedBox(height: 20),
          const Text('미리보기', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
            child: _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  _PreviewMember(initial: '이', name: '이효자', desc: '딸 · 010-1234-5678', color: Color(0xFFFFD6E7)),
                  Divider(height: 1),
                  _PreviewMember(initial: '박', name: '박효자', desc: '아들 · 010-5678-1234', color: Color(0xFFD8F6D9)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('설정한 글자 크기는 앱 전체에 적용됩니다.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 26),
          const Text('기타 표시 옵션', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: boldText,
                  onChanged: (v) => setState(() => boldText = v),
                  title: const Text('굵은 글씨 사용', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('주요 텍스트를 더 굵게 표시합니다.'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: highContrast,
                  onChanged: (v) => setState(() => highContrast = v),
                  title: const Text('고대비 모드', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('배경과 텍스트의 대비를 높입니다.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () => setState(() {
              textScale = 1.0;
              boldText = true;
              highContrast = false;
            }),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF334155), minimumSize: const Size.fromHeight(56)),
            child: const Text('기본 설정으로 되돌리기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 30),
          const Center(child: Text('링크 v1.0.0', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _PreviewMember extends StatelessWidget {
  const _PreviewMember({required this.initial, required this.name, required this.desc, required this.color});
  final String initial;
  final String name;
  final String desc;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(radius: 26, backgroundColor: color, child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(desc, style: const TextStyle(color: Color(0xFF64748B)))])),
        ]),
      );
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
