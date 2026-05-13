import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 더보기에서 설정하는 푸시·전화 복용 알림 시각(로컬 [SharedPreferences]).
abstract final class ReminderChannelPrefs {
  static const _pushOn = 'reminder_push_enabled';
  static const _pushH = 'reminder_push_hour';
  static const _pushM = 'reminder_push_minute';
  static const _phoneOn = 'reminder_phone_enabled';
  static const _phoneH = 'reminder_phone_hour';
  static const _phoneM = 'reminder_phone_minute';
  static const _phoneMsg = 'reminder_phone_message_v1';

  static Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  static Future<bool> pushEnabled() async {
    final p = await _p();
    return p.getBool(_pushOn) ?? true;
  }

  static Future<void> setPushEnabled(bool v) async {
    (await _p()).setBool(_pushOn, v);
  }

  static Future<TimeOfDay> pushTime() async {
    final p = await _p();
    final h = p.getInt(_pushH) ?? 9;
    final m = p.getInt(_pushM) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static Future<void> setPushTime(TimeOfDay t) async {
    final p = await _p();
    await p.setInt(_pushH, t.hour);
    await p.setInt(_pushM, t.minute);
  }

  static Future<String> pushTimeHm() async {
    final t = await pushTime();
    final mm = t.minute.toString().padLeft(2, '0');
    return '${t.hour}:$mm';
  }

  static Future<bool> phoneEnabled() async {
    final p = await _p();
    return p.getBool(_phoneOn) ?? false;
  }

  static Future<void> setPhoneEnabled(bool v) async {
    (await _p()).setBool(_phoneOn, v);
  }

  static Future<TimeOfDay> phoneTime() async {
    final p = await _p();
    final h = p.getInt(_phoneH) ?? 10;
    final m = p.getInt(_phoneM) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static Future<void> setPhoneTime(TimeOfDay t) async {
    final p = await _p();
    await p.setInt(_phoneH, t.hour);
    await p.setInt(_phoneM, t.minute);
  }

  static Future<String> phoneTimeHm() async {
    final t = await phoneTime();
    final mm = t.minute.toString().padLeft(2, '0');
    return '${t.hour}:$mm';
  }

  static Future<String> phoneMessage() async {
    final p = await _p();
    return p.getString(_phoneMsg) ?? '';
  }

  static Future<void> setPhoneMessage(String v) async {
    (await _p()).setString(_phoneMsg, v.trim());
  }
}
