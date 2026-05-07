import 'package:flutter/foundation.dart';

/// Push service stub until Firebase/APNs is integrated.
class PushNotificationService {
  Future<void> initialize() async {
    debugPrint('PushNotificationService: initialization stub');
  }

  Future<void> requestPermission() async {
    debugPrint('PushNotificationService: request permission stub');
  }
}