import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tilko_pass_uri_extract.dart';

/// 틸코 NHIS/PASS 간편인증 후 PASS 앱·인증 화면 실행.
abstract final class TilkoPassLaunch {
  /// 틸코 `simpleauthrequest` 응답 JSON에서 PASS 실행 URL을 수집합니다.
  static List<String> extractLaunchUrisFromTilko(dynamic root) =>
      TilkoPassUriExtract.extractLaunchUrisFromTilko(root);

  static const List<String> _schemePrefixesForOpen = <String>[
    'tauthlink://',
    'ktauthexternalcall://',
    'upluscorporation://',
    'sktpass://',
    'ktpass://',
    'upluspass://',
    'pass://',
  ];

  static const _packageIds = <String>[
    'com.sktelecom.tauth',
    'com.kt.ktauth',
    'com.lguplus.smartotp',
  ];

  /// 틸코 URL → 통신사 기본 scheme → 설치된 PASS 앱(package) 순으로 시도.
  static Future<bool> openAuthScreen({List<String> tilkoUris = const []}) async {
    for (final raw in tilkoUris) {
      if (await _tryUri(Uri.parse(raw))) return true;
    }

    for (final scheme in _schemePrefixesForOpen) {
      if (await _tryUri(Uri.parse(scheme))) return true;
    }

    for (final pkg in _packageIds) {
      final intent = Uri.parse(
        'intent://#Intent;package=$pkg;scheme=${_schemeForPackage(pkg)};end',
      );
      if (await _tryUri(intent)) return true;
    }
    return false;
  }

  static String _schemeForPackage(String pkg) {
    switch (pkg) {
      case 'com.sktelecom.tauth':
        return 'tauthlink';
      case 'com.kt.ktauth':
        return 'ktauthexternalcall';
      case 'com.lguplus.smartotp':
        return 'upluscorporation';
      default:
        return 'pass';
    }
  }

  static Future<bool> _tryUri(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TilkoPassLaunch: $uri — $e');
      }
      return false;
    }
  }
}
