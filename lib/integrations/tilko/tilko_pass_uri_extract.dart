import 'dart:convert';

/// 틸코 NHIS/PASS 응답에서 실행 URL만 파싱 — Flutter/`dart:ui` 없음.
/// [tool/link26_bff.dart] 등 VM에서 `dart run` 가능하도록 분리.
abstract final class TilkoPassUriExtract {
  static const _schemePrefixes = <String>[
    'tauthlink://',
    'ktauthexternalcall://',
    'upluscorporation://',
    'sktpass://',
    'ktpass://',
    'upluspass://',
    'pass://',
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
}
