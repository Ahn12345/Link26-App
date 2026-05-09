import 'package:flutter/foundation.dart';

/// 건강보험심사평가원·공단 연계 스텁.
/// 실제 간편인증·API URL·인증서는 이후 [ApiConfig] 및 서버 BFF와 연결.
abstract final class HiraLinkService {
  static Future<void> afterRegistration() async {
    debugPrint('HIRA: post-registration link (stub)');
  }

  static Future<void> afterLogin() async {
    debugPrint('HIRA: auto link after login (stub)');
  }

  static Future<void> afterMonthlyEasyAuth() async {
    debugPrint('HIRA: monthly easy-auth token refresh (stub)');
  }
}
