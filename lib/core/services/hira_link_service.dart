import 'package:flutter/foundation.dart';

/// 건강보험심사평가원·공단 연계 스텁.
/// 복약 목록 NHIS/BFF 동기화는 홈 [HomeDashboardContent] 진입·당겨서 새로고침에서 수행합니다.
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
