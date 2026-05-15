import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:link26_app/core/constants/api_keys.dart';

/// 릴리스에서 BFF 베이스 URL을 **원격 JSON**으로 내려받아 캐시합니다.
///
/// 매니페스트 URL: [manifestUrl] (`LINK26_REMOTE_CONFIG_URL` dotenv 또는
/// `--dart-define=LINK26_REMOTE_CONFIG_URL=https://…/link26-bff.json`).
///
/// JSON 예:
/// ```json
/// { "nhisBffBases": ["https://api.example.com", "https://api-backup.example.com"] }
/// ```
/// 또는 단일 키: `nhisBffBase`, `nhis_production_base_url` (문자열, 쉼표 구분 가능).
///
/// [NhisRuntimeConfig.baseUrlCandidates] 릴리스 분기에서
/// `NHIS_PRODUCTION_BASE_URL` 이 비었을 때 여기 캐시를 뒤집니다.
abstract final class Link26RemoteBffBootstrap {
  static const _prefsKeyBody = 'link26_remote_nhis_bff_manifest_v1';

  static final List<String> _memoryBases = <String>[];

  /// 홈 등에서 원격 BFF 목록이 갱신되면 증가합니다.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static List<String> get cachedReleaseBases =>
      List<String>.unmodifiable(_memoryBases);

  static String _stripQuotes(String? raw) {
    var v = (raw ?? '').trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }

  static String get manifestUrl {
    final d = ApiConfig.link26RemoteConfigUrl.trim();
    if (d.isNotEmpty) return d;
    return _stripQuotes(dotenv.env['LINK26_REMOTE_CONFIG_URL']);
  }

  static bool _manifestUrlAllowed(String url) {
    final u = url.trim().toLowerCase();
    if (u.startsWith('https://')) return true;
    if (kDebugMode && u.startsWith('http://')) return true;
    return false;
  }

  static bool _baseAllowed(String base) {
    final b = base.trim().toLowerCase();
    if (b.startsWith('https://')) return true;
    if (kDebugMode && b.startsWith('http://')) return true;
    return false;
  }

  static void _bumpRevision() {
    revision.value = revision.value + 1;
  }

  static List<String> _splitBases(String raw) {
    if (raw.isEmpty) return const [];
    final parts = raw.split(RegExp(r'[\s,;]+'));
    final out = <String>[];
    for (final p in parts) {
      var s = p.trim();
      if (s.isEmpty) continue;
      while (s.endsWith('/')) {
        s = s.substring(0, s.length - 1);
      }
      if (s.isNotEmpty && _baseAllowed(s)) out.add(s);
    }
    return out;
  }

  static List<String> _parseManifestObject(Map<String, dynamic> map) {
    final bases = map['nhisBffBases'];
    if (bases is List) {
      final raw = bases.map((e) => '$e').where((s) => s.trim().isNotEmpty).toList();
      return _splitBases(raw.join(','));
    }
    final single = map['nhisBffBase'] ??
        map['nhis_production_base_url'] ??
        map['NHIS_PRODUCTION_BASE_URL'];
    if (single is String) return _splitBases(single);
    return const [];
  }

  /// [body] 는 JSON 객체 문자열입니다.
  static List<String> parseManifestBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        return _parseManifestObject(map);
      }
    } catch (_) {}
    return const [];
  }

  static void _applyIfChanged(List<String> next) {
    if (listEquals(_memoryBases, next)) return;
    _memoryBases
      ..clear()
      ..addAll(next);
    _bumpRevision();
  }

  /// [SharedPreferences] 에서 마지막 성공 본문을 읽어 메모리에 반영합니다.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyBody);
      if (raw == null || raw.trim().isEmpty) return;
      final parsed = parseManifestBody(raw);
      if (parsed.isEmpty) return;
      _applyIfChanged(parsed);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Link26RemoteBffBootstrap.init: $e');
      }
    }
  }

  /// 네트워크에서 매니페스트를 받아 저장합니다.
  static Future<void> refreshFromNetwork({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final url = manifestUrl.trim();
    if (url.isEmpty) return;
    if (!_manifestUrlAllowed(url)) {
      if (kDebugMode) {
        debugPrint(
          'Link26RemoteBffBootstrap: manifest URL 허용 안 됨(HTTPS 필요): $url',
        );
      }
      return;
    }
    try {
      final res = await http.get(Uri.parse(url)).timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            'Link26RemoteBffBootstrap: HTTP ${res.statusCode} for $url',
          );
        }
        return;
      }
      final parsed = parseManifestBody(res.body);
      if (parsed.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Link26RemoteBffBootstrap: JSON에 nhisBffBases 등 유효 필드 없음',
          );
        }
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyBody, res.body);
      _applyIfChanged(parsed);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Link26RemoteBffBootstrap.refreshFromNetwork: $e');
      }
    }
  }

  static void scheduleBackgroundRefresh() {
    final url = manifestUrl.trim();
    if (url.isEmpty) return;
    unawaited(refreshFromNetwork());
  }
}
