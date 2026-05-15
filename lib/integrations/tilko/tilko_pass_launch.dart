import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 틸코 NHIS/PASS 간편인증 후 PASS 앱·인증 화면 실행.
abstract final class TilkoPassLaunch {
  static const _schemePrefixes = <String>[
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

  /// 틸코 `simpleauthrequest` 응답 JSON에서 PASS 실행 URL을 수집합니다.
  static List<String> extractLaunchUrisFromTilko(dynamic root) {
    final found = <String>{};
    void walk(dynamic node) {
      if (node is Map) {
        for (final e in node.entries) {
          final key = '${e.key}'.toLowerCase();
          if (key.contains('scheme') ||
              key.contains('deeplink') ||
              key.contains('authurl') ||
              key.contains('applink') ||
              key.contains('launch')) {
            _collectUriStrings(found, '${e.value}');
          }
          walk(e.value);
        }
      } else if (node is List) {
        for (final e in node) {
          walk(e);
        }
      } else if (node is String) {
        _collectUriStrings(found, node);
      }
    }

    walk(root);
    return found.toList();
  }

  static void _collectUriStrings(Set<String> out, String raw) {
    var s = raw.trim();
    if (s.isEmpty || s == 'null') return;
    if (s.startsWith('{') || s.startsWith('[')) {
      try {
        _collectFromDecoded(out, jsonDecode(s));
        return;
      } catch (_) {}
    }
    _collectFromDecoded(out, s);
  }

  static void _collectFromDecoded(Set<String> out, dynamic decoded) {
    if (decoded is String) {
      final t = decoded.trim();
      if (_looksLikePassUri(t)) out.add(t);
      final intentScheme = _schemeFromAndroidIntent(t);
      if (intentScheme != null) out.add(intentScheme);
    } else if (decoded is Map) {
      for (final v in decoded.values) {
        _collectFromDecoded(out, v);
      }
    } else if (decoded is List) {
      for (final v in decoded) {
        _collectFromDecoded(out, v);
      }
    }
  }

  static bool _looksLikePassUri(String s) {
    final lower = s.toLowerCase();
    if (lower.startsWith('intent://')) return true;
    for (final p in _schemePrefixes) {
      if (lower.startsWith(p)) return true;
    }
    return false;
  }

  /// `intent://...#Intent;scheme=tauthlink;...` 에서 scheme URI 추출.
  static String? _schemeFromAndroidIntent(String intent) {
    if (!intent.toLowerCase().startsWith('intent://')) return null;
    final m = RegExp(
      r'scheme=([a-zA-Z][a-zA-Z0-9+.-]*)',
      caseSensitive: false,
    ).firstMatch(intent);
    if (m == null) return null;
    final scheme = m.group(1);
    if (scheme == null || scheme.isEmpty) return null;
    final path = intent.split('#').first;
    final afterScheme = path.contains('://')
        ? path.substring(path.indexOf('://') + 3)
        : '';
    if (afterScheme.isNotEmpty && afterScheme != '/') {
      return '$scheme://$afterScheme';
    }
    return '$scheme://';
  }

  /// 틸코 URL → 통신사 기본 scheme → 설치된 PASS 앱(package) 순으로 시도.
  static Future<bool> openAuthScreen({List<String> tilkoUris = const []}) async {
    for (final raw in tilkoUris) {
      if (await _tryUri(Uri.parse(raw))) return true;
    }

    for (final scheme in _schemePrefixes) {
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
