import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:link26_app/integrations/nhis/nhis_endpoints.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

/// PC BFF(`/health`) 도달 여부 — 여러 `NHIS_BASE_URL` 순차 대기(수십 초) 방지.
abstract final class Link26BffReachability {
  static const Duration _probeTimeout = Duration(milliseconds: 1600);
  static const Duration _cacheTtl = Duration(seconds: 40);
  static const Duration _perHostNegativeTtl = Duration(seconds: 50);

  static DateTime? _lastProbeAt;
  static List<String> _ordered = const [];
  static bool _anyReachable = false;
  static final Map<String, DateTime> _hostOkUntil = {};
  static final Map<String, DateTime> _hostFailUntil = {};

  static bool get fastProbeEnabled {
    if (kReleaseMode) return true;
    final v =
        (NhisRuntimeConfig.envRaw('NHIS_BFF_FAST_PROBE') ?? '').trim().toLowerCase();
    if (v == 'false' || v == '0' || v == 'no') return false;
    return true;
  }

  static bool get recentlyAllUnreachable {
    if (!fastProbeEnabled || _lastProbeAt == null) return false;
    if (DateTime.now().difference(_lastProbeAt!) > _cacheTtl) return false;
    return !_anyReachable;
  }

  static bool get hasReachableBase => _anyReachable;

  static List<String> get lastOrderedBases => List<String>.unmodifiable(_ordered);

  static String? firstReachable(Iterable<String> ordered) {
    for (final b in ordered) {
      if (_hostOkUntil.containsKey(_normalize(b))) return _normalize(b);
    }
    return null;
  }

  static List<String> reachableOnly(Iterable<String> ordered) {
    final out = <String>[];
    for (final b in ordered) {
      final n = _normalize(b);
      if (n.isEmpty) continue;
      if (_hostOkUntil.containsKey(n)) out.add(n);
    }
    return out;
  }

  /// 「심평원에서 불러오기」 직전 등 — 이전 /health 실패 캐시를 비웁니다.
  static void clearProbeCache() {
    _lastProbeAt = null;
    _ordered = const [];
    _anyReachable = false;
    _hostOkUntil.clear();
    _hostFailUntil.clear();
  }

  /// 앱 기동·당겨서 새로고침 시 호출. 도달 가능한 BFF를 앞에 둡니다.
  static Future<void> warmUp(List<String> candidates) async {
    if (!fastProbeEnabled || candidates.isEmpty) {
      _ordered = List<String>.from(candidates);
      _anyReachable = false;
      _lastProbeAt = DateTime.now();
      return;
    }

    final unique = <String>[];
    final seen = <String>{};
    for (final raw in candidates) {
      final n = _normalize(raw);
      if (n.isEmpty || seen.contains(n)) continue;
      seen.add(n);
      unique.add(n);
    }

    final reachable = <String>[];
    final unreachable = <String>[];

    await Future.wait(
      unique.map((base) async {
        if (await _probeHealth(base)) {
          reachable.add(base);
        } else {
          unreachable.add(base);
        }
      }),
    );

    _ordered = [...reachable, ...unreachable];
    _anyReachable = reachable.isNotEmpty;
    _lastProbeAt = DateTime.now();

    if (kDebugMode) {
      debugPrint(
        'Link26BffReachability: reachable=${reachable.length}/${unique.length} '
        '${reachable.isEmpty ? "(PC BFF 없음 — BFF 호출 생략)" : "first=${reachable.first}"}',
      );
    }
  }

  static Future<bool> _probeHealth(String base) async {
    final b = _normalize(base);
    if (b.isEmpty) return false;

    final now = DateTime.now();
    final okUntil = _hostOkUntil[b];
    if (okUntil != null && now.isBefore(okUntil)) return true;
    final failUntil = _hostFailUntil[b];
    if (failUntil != null && now.isBefore(failUntil)) return false;

    final uri = Uri.parse('$b${NhisEndpoints.health}');
    try {
      final res = await http.get(uri).timeout(_probeTimeout);
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (ok) {
        _hostOkUntil[b] = now.add(_perHostNegativeTtl);
        _hostFailUntil.remove(b);
      } else {
        _hostFailUntil[b] = now.add(_perHostNegativeTtl);
        _hostOkUntil.remove(b);
      }
      return ok;
    } on TimeoutException {
      _markFail(b, now);
      return false;
    } on SocketException {
      _markFail(b, now);
      return false;
    } on IOException {
      _markFail(b, now);
      return false;
    } catch (_) {
      _markFail(b, now);
      return false;
    }
  }

  static void _markFail(String base, DateTime now) {
    _hostFailUntil[base] = now.add(_perHostNegativeTtl);
    _hostOkUntil.remove(base);
  }

  static String _normalize(String raw) {
    var s = raw.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
