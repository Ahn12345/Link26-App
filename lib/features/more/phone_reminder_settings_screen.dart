import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:link26_app/core/services/reminder_channel_prefs.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';

/// 전화 형태 복용 안내용 문구(음성 입력)·알림 시각.
class PhoneReminderSettingsScreen extends StatefulWidget {
  const PhoneReminderSettingsScreen({super.key});

  @override
  State<PhoneReminderSettingsScreen> createState() =>
      _PhoneReminderSettingsScreenState();
}

class _PhoneReminderSettingsScreenState
    extends State<PhoneReminderSettingsScreen> {
  final _msgCtrl = TextEditingController();
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _speechReady = false;
  bool _phoneOn = false;
  TimeOfDay _phoneTime = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await ReminderChannelPrefs.phoneEnabled();
    final t = await ReminderChannelPrefs.phoneTime();
    final msg = await ReminderChannelPrefs.phoneMessage();
    if (!mounted) return;
    setState(() {
      _phoneOn = on;
      _phoneTime = t;
      _msgCtrl.text = msg;
      _loading = false;
    });
  }

  Future<void> _initSpeech() async {
    if (_speechReady) return;
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListen() async {
    await _initSpeech();
    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 기기에서 음성 인식을 쓸 수 없습니다.')),
        );
      }
      return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          _msgCtrl.text = r.recognizedWords;
          _msgCtrl.selection = TextSelection.collapsed(
            offset: _msgCtrl.text.length,
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ko_KR',
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _phoneTime,
    );
    if (picked == null) return;
    await ReminderChannelPrefs.setPhoneTime(picked);
    if (mounted) setState(() => _phoneTime = picked);
  }

  Future<void> _persistMessage() async {
    await ReminderChannelPrefs.setPhoneMessage(_msgCtrl.text);
  }

  @override
  void dispose() {
    _speech.stop();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Link26Surface.scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: Text(
                    '전화 알림 설정',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '홈 「오늘의 알림」에 전화형 복용 안내로 표시됩니다. 실제 전화 발신은 '
              '통신사·백엔드 연동 시 별도로 구성할 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: Link26Surface.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '전화 알림 사용',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('설정한 시각에 전화형 알림 카드가 추가됩니다.'),
                value: _phoneOn,
                activeThumbColor: Link26Surface.accent,
                onChanged: (v) async {
                  await ReminderChannelPrefs.setPhoneEnabled(v);
                  setState(() => _phoneOn = v);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '전화 알림 시각',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  _phoneTime.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Link26Surface.accent,
                  ),
                ),
                trailing: const Icon(Icons.schedule_rounded),
                onTap: _pickTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 18),
              const Text(
                '안내 멘트',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _msgCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '예: 혈압약 드실 시간이에요',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: IconButton(
                    tooltip: _listening ? '음성 입력 중지' : '음성 입력',
                    onPressed: _toggleListen,
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_none_rounded,
                      color: _listening ? Colors.red : Link26Surface.accent,
                    ),
                  ),
                ),
                onChanged: (_) => _persistMessage(),
                onEditingComplete: _persistMessage,
              ),
              const SizedBox(height: 12),
              Text(
                '마이크 권한이 필요합니다. 입력이 끝나면 저장되어 홈 알림 제목으로 쓰입니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Link26Surface.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
