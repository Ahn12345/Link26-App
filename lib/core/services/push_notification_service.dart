import 'package:flutter/foundation.dart';

/// FCM/APNs 등 푸시 초기화 스텁. Firebase 설정 후 연동.
class PushNotificationService {
  Future<void> initialize() async {
    debugPrint('PushNotificationService: Firebase 미연동 — 초기화 스텁');
  }

  Future<void> requestPermission() async {
    debugPrint('PushNotificationService: 권한 요청 스텁');
  }
}
