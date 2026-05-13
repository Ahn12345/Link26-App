import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:link26_app/core/services/reminder_channel_prefs.dart';

/// 복용 알림 — 앱이 꺼져 있어도 **로컬 예약 알림**으로 표시합니다.
/// (실제 **전화 발신/착신**은 통신사·백엔드 연동이 별도로 필요합니다.)
abstract final class DoseReminderNotifications {
  static const int _pushId = 9101;
  static const int _phoneId = 9102;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;

    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e, st) {
      debugPrint('DoseReminderNotifications: timezone $e\n$st');
    }

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(const AndroidNotificationChannel(
        'dose_daily_push',
        '복용 알림',
        description: '매일 설정 시각 복용 안내',
        importance: Importance.high,
      ));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        'dose_daily_call_style',
        '복용 알림(강조)',
        description: '소리·헤드업 강조(실제 전화 아님)',
        importance: Importance.max,
      ));
      await android.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _inited = true;
  }

  /// 더보기·전화 알림 설정에서 바뀔 때마다 호출합니다.
  static Future<void> rescheduleFromPrefs() async {
    await init();
    await _plugin.cancel(id: _pushId);
    await _plugin.cancel(id: _phoneId);

    if (await ReminderChannelPrefs.pushEnabled()) {
      final t = await ReminderChannelPrefs.pushTime();
      await _scheduleDaily(
        id: _pushId,
        title: '푸시 복용 알림',
        body: '복약 시간입니다. 앱에서 확인해 주세요.',
        hour: t.hour,
        minute: t.minute,
        channelId: 'dose_daily_push',
        channelName: '복용 알림',
        importance: Importance.high,
      );
    }

    if (await ReminderChannelPrefs.phoneEnabled()) {
      final t = await ReminderChannelPrefs.phoneTime();
      final msg = (await ReminderChannelPrefs.phoneMessage()).trim();
      final title = msg.isEmpty ? '전화 복용 알림' : msg;
      await _scheduleDaily(
        id: _phoneId,
        title: title,
        body: '복용 안내입니다. (시스템 알림 · 실제 전화 아님)',
        hour: t.hour,
        minute: t.minute,
        channelId: 'dose_daily_call_style',
        channelName: '복용 알림(강조)',
        importance: Importance.max,
      );
    }
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required Importance importance,
  }) async {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Link26 복용 알림',
      importance: importance,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
