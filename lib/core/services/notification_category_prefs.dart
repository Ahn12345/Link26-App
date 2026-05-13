import 'package:shared_preferences/shared_preferences.dart';

/// 「알림 설정」화면의 전체·항목별 스위치 — [SharedPreferences]에 저장합니다.
abstract final class NotificationCategoryPrefs {
  static const _kMsg = 'notif_item_message_v1';
  static const _kFam = 'notif_item_family_v1';
  static const _kNotice = 'notif_item_notice_v1';
  static const _kEvent = 'notif_item_event_v1';

  static Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  static Future<bool> messageEnabled() async =>
      (await _p()).getBool(_kMsg) ?? true;

  static Future<bool> familyEnabled() async =>
      (await _p()).getBool(_kFam) ?? true;

  static Future<bool> noticeEnabled() async =>
      (await _p()).getBool(_kNotice) ?? true;

  static Future<bool> eventEnabled() async =>
      (await _p()).getBool(_kEvent) ?? true;

  /// 네 항목이 모두 켜져 있을 때만 true (마스터 스위치 표시용).
  static Future<bool> allEnabled() async {
    final m = await messageEnabled();
    final f = await familyEnabled();
    final n = await noticeEnabled();
    final e = await eventEnabled();
    return m && f && n && e;
  }

  static Future<void> setMessage(bool v) async => (await _p()).setBool(_kMsg, v);

  static Future<void> setFamily(bool v) async => (await _p()).setBool(_kFam, v);

  static Future<void> setNotice(bool v) async =>
      (await _p()).setBool(_kNotice, v);

  static Future<void> setEvent(bool v) async => (await _p()).setBool(_kEvent, v);

  /// 「전체 알림」— 네 항목을 한꺼번에 켜거나 끕니다.
  static Future<void> setAll(bool v) async {
    final p = await _p();
    await p.setBool(_kMsg, v);
    await p.setBool(_kFam, v);
    await p.setBool(_kNotice, v);
    await p.setBool(_kEvent, v);
  }
}
