import 'package:flutter/foundation.dart';

/// FCM/APNs ???�시 초기???�텁. Firebase ?�정 ???�동.
class PushNotificationService {
  Future<void> initialize() async {
    debugPrint('PushNotificationService: Firebase 미연????초기???�텁');
  }

  Future<void> requestPermission() async {
    debugPrint('PushNotificationService: 권한 ?�청 ?�텁');
  }
}
