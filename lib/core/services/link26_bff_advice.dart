import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

/// 실제 기기에서 잘못된 BFF 주소(에뮬/루프백)를 쓸 때 홈 알림으로 안내합니다.
abstract final class Link26BffAdvice {
  static String? _pendingKo;

  static Future<void> evaluateAfterDotenv() async {
    _pendingKo = null;
    if (!dotenv.isInitialized) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        if (!a.isPhysicalDevice) return;
      } else {
        final ios = await plugin.iosInfo;
        if (!ios.isPhysicalDevice) return;
      }

      final url = NhisRuntimeConfig.baseUrl.trim().toLowerCase();
      if (url.isEmpty) return;

      if (url.contains('10.0.2.2')) {
        _pendingKo =
            '실제 기기에서는 NHIS_BASE_URL에 PC의 Wi‑Fi IP(예: http://192.168.x.x:8787)를 쓰세요. '
            '10.0.2.2는 Android 에뮬레이터→PC 전용입니다. .env 수정 후 sync_dotenv(또는 run_bff_and_flutter.ps1)로 '
            'assets/env/dotenv를 갱신하고 앱을 다시 빌드하세요. PC에서 BFF 실행·Windows 방화벽도 확인하세요.';
      } else if (url.contains('127.0.0.1') || url.contains('localhost')) {
        _pendingKo =
            '실제 기기에서는 127.0.0.1/localhost 대신 PC의 LAN IP(192.168.x.x)를 NHIS_BASE_URL에 넣으세요. '
            '127.0.0.1은 이 폰 자신을 가리킵니다.';
      }
    } catch (_) {}
  }

  /// 한 번만 시스템 알림으로 올린 뒤 호출해 소비합니다.
  static String? takePendingNoticeKo() {
    final m = _pendingKo;
    _pendingKo = null;
    return m;
  }
}
