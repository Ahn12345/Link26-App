import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import 'package:link26_app/app.dart';

/// 표시 설정 — 글자 크기는 [Link26AppState.setTextScaleFactor] 로 앱 전체에 반영됩니다.
class DisplaySettingScreen extends StatefulWidget {
  const DisplaySettingScreen({super.key});

  @override
  State<DisplaySettingScreen> createState() => _DisplaySettingScreenState();
}

class _DisplaySettingScreenState extends State<DisplaySettingScreen> {
  double textScale = 1.0;
  bool bold = true;
  bool highContrast = false;

  static const double _minScale = 0.85;
  static const double _maxScale = 1.35;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = Link26App.maybeOf(context);
      if (!mounted) return;
      if (app != null) {
        setState(() => textScale = app.currentTextScale);
      }
    });
  }

  Future<void> _applyScale(double v) async {
    final clamped = v.clamp(_minScale, _maxScale);
    setState(() => textScale = clamped);
    await Link26App.maybeOf(context)?.setTextScaleFactor(clamped);
  }

  Future<void> reset() async {
    setState(() {
      textScale = 1.0;
      bold = false;
      highContrast = false;
    });
    await Link26App.maybeOf(context)?.setTextScaleFactor(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w900 : FontWeight.w500;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Text('표시 설정', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('글자 크기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const Text('앱 전체의 글자 크기를 조절할 수 있습니다.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFF0B6BFF),
                    child: Text('김', style: TextStyle(color: Colors.white, fontSize: 32)),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('김건강', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      Text('kimhealth@example.com'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Row(children: [Text('작게'), Spacer(), Text('크게')]),
            Slider(
              value: textScale.clamp(_minScale, _maxScale),
              min: _minScale,
              max: _maxScale,
              divisions: 10,
              label: textScale == 1.0 ? '보통' : textScale.toStringAsFixed(2),
              onChanged: (v) => unawaited(_applyScale(v)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: highContrast ? Colors.black : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 16 * textScale,
                  color: highContrast ? Colors.white : Colors.black,
                  fontWeight: weight,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('미리보기'),
                    SizedBox(height: 12),
                    Text('이효자\n딸 · 010-1234-5678'),
                    Divider(),
                    Text('박효자\n아들 · 010-5678-1234'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('기타 표시 옵션', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SwitchListTile(
              title: const Text('굵은 글씨 사용'),
              subtitle: const Text('주요 텍스트를 더 굵게 표시합니다.'),
              value: bold,
              onChanged: (v) => setState(() => bold = v),
            ),
            SwitchListTile(
              title: const Text('고대비 모드'),
              subtitle: const Text('배경과 텍스트의 대비를 높입니다.'),
              value: highContrast,
              onChanged: (v) => setState(() => highContrast = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: Colors.black,
              ),
              child: const Text('기본 설정으로 되돌리기'),
            ),
          ],
        ),
      ),
    );
  }
}
