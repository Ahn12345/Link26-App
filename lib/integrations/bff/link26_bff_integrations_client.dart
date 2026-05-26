import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:link26_app/core/services/link26_bff_reachability.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

final _codfRedirectRe = RegExp(r'CODEF HTTP (301|302|303|307|308)');

String _codfRedirectHintKo() =>
    'CODEF가 HTTP 리다이렉트(301·302·303·307·308)로 응답했습니다. '
    'BFF를 최신 코드로 재시작했는지·콘솔에 `CODEF: HTTP … Location=` 로그가 있는지 확인하고, '
    'CODEF_BASE_URL·키 종류(샌드박스·개발·운영)와 CODEF_NHIS_TREATMENT_PATH를 '
    'developer.codef.io 기준으로 맞추세요.';

String _stripBom(String s) {
  var t = s.trim();
  if (t.startsWith('\uFEFF')) {
    t = t.substring(1).trim();
  }
  return t;
}

/// BFF가 `TILKO_API_KEY` 비어 있음을 알릴 때 — 스낵바는 짧게, 자세한 건 디버그 로그.
String _tilkoKeyMissingHintKo() =>
    '심평원·복약 연동은 PC의 BFF가 틸코를 호출합니다. '
    '프로젝트 루트 .env에 TILKO_API_KEY를 넣고 BFF를 다시 실행해 주세요.';

String _rewriteTilkoEnvHint(String msg) {
  final s = msg.trim();
  final tilko = tilkoUserFacingMessageKo(s);
  if (tilko != s) return tilko;
  if (s.contains('TILKO_API_KEY') &&
      (s.contains('비어') || s.toLowerCase().contains('empty'))) {
    if (kDebugMode) {
      debugPrint(
        'Link26: Tilko — PC `dart run tool/link26_bff.dart` 가 읽는 루트 .env에 '
        'TILKO_API_KEY(필수), TILKO_API_HOST(선택, 기본 dev.tilko.net). '
        '앱 assets/env/dotenv 는 NHIS_BASE_URL 위주.',
      );
    }
    return _tilkoKeyMissingHintKo();
  }
  return msg;
}

String _flowHttpErrorDetail(int statusCode, String body) {
  final flat = _stripBom(body);
  if (flat.isNotEmpty && _codfRedirectRe.hasMatch(flat)) {
    return _codfRedirectHintKo();
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final hint = decoded['hint_ko'];
      if (hint is String && hint.trim().isNotEmpty) {
        return _rewriteTilkoEnvHint(hint.trim());
      }
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        final d = detail.trim();
        if (_codfRedirectRe.hasMatch(d)) {
          return _codfRedirectHintKo();
        }
        if (d.contains('CODEF HTTP')) {
          return 'CODEF 연동 오류입니다. BFF .env의 CODEF 클라이언트·호스트·상품 경로를 '
              '확인하거나 PC에서 BFF 로그를 확인하세요.\n($d)';
        }
        return _rewriteTilkoEnvHint(d);
      }
    }
  } catch (_) {}
  if (body.trim().isNotEmpty) return body.trim();
  return 'HTTP $statusCode';
}

/// 이 레포의 **Dart BFF**(`dart run tool/link26_bff.dart`)에만 붙입니다.
///
/// `NHIS_BASE_URL`은 BFF 베이스(예: `http://10.0.2.2:8787`) 하나이거나,
/// Wi-Fi·이더넷 등 쉼표로 구분한 여러 베이스(연결 실패 시 순서대로 재시도)입니다.
///
/// 틸코 API 키 등은 BFF 루트 `.env`에 두고, 앱은 NHIS_BASE_URL만 알면 됩니다.
///
/// [NhisRuntimeConfig.useMock] 은 가입·로그인·복약 동기화용 목 데이터에만 쓰이고,
/// 여기 BFF 프록시(e약은요·틸코·플로우)는 막지 않습니다.
abstract final class Link26BffIntegrationsClient {
  /// `phase=start` 가 성공한 BFF 베이스 — `continue` 에 같은 주소만 사용(다른 IP 재시도 방지).
  static String? _lastSuccessfulFlowBase;

  static void clearLastSuccessfulFlowBase() => _lastSuccessfulFlowBase = null;

  /// [NhisTilkoHiraFlowSync] 등 catch 블록에서 `StateError` 전체 문자열을 넣을 때 —
  /// `flow HTTP 502: {"detail":"…"}` 형태를 스낵바용 한글로 줄입니다.
  static String sanitizeIntegrationErrorMessage(String raw) {
    var t = _stripBom(raw);
    const badState = 'Bad state: ';
    if (t.startsWith(badState)) {
      t = t.substring(badState.length).trim();
    }
    if (t.isEmpty) return '건강 연동에 실패했습니다.';
    if (_codfRedirectRe.hasMatch(t)) return _codfRedirectHintKo();

    final flowHead = RegExp(r'flow HTTP (\d+):\s*', caseSensitive: false);
    final m = flowHead.firstMatch(t);
    if (m != null) {
      final code = int.tryParse(m.group(1) ?? '') ?? 0;
      final rest = t.substring(m.end).trim();
      if (rest.startsWith('{')) {
        return _rewriteTilkoEnvHint(_flowHttpErrorDetail(code, rest));
      }
      if (rest.isNotEmpty) {
        return _rewriteTilkoEnvHint(rest);
      }
    }
    final clipped = t.length > 420 ? '${t.substring(0, 420)}…' : t;
    return _rewriteTilkoEnvHint(clipped);
  }

  static String get _basesDebug =>
      NhisRuntimeConfig.baseUrlCandidates.join(' | ');

  static List<String> get _baseList => NhisRuntimeConfig.baseUrlCandidates;

  static bool get canCall {
    if (_baseList.isEmpty) return false;
    // 디버그: /health 프로브 실패만으로 막지 않음(USB·Wi‑Fi 전환·BFF 늦게 켬).
    if (kReleaseMode &&
        Link26BffReachability.fastProbeEnabled &&
        Link26BffReachability.recentlyAllUnreachable) {
      return false;
    }
    return true;
  }

  static List<String> get _activeBases {
    if (!canCall) return const [];
    final reachable = Link26BffReachability.reachableOnly(
      Link26BffReachability.lastOrderedBases,
    );
    if (reachable.isNotEmpty) return reachable;
    // 릴리스만 프로브 실패 시 빈 목록. 디버그는 dotenv 후보로 POST 시도(canCall 과 동일).
    if (kReleaseMode && Link26BffReachability.recentlyAllUnreachable) {
      return const [];
    }
    return _baseList;
  }

  static bool _shouldRetryBffOn(
    Object e,
    int index,
    int total, {
    bool allowTimeoutRetry = true,
  }) {
    if (index >= total - 1) return false;
    if (e is TimeoutException) return allowTimeoutRetry;
    return link26ErrorLooksLikeUnreachableHost(e);
  }

  static List<String> _basesForFlowPhase(String phase) {
    if (phase == 'continue' &&
        _lastSuccessfulFlowBase != null &&
        _lastSuccessfulFlowBase!.trim().isNotEmpty) {
      final first = _lastSuccessfulFlowBase!.trim();
      final rest = <String>[];
      for (final b in _activeBases) {
        if (b != first) rest.add(b);
      }
      // PASS 복귀 후 Wi‑Fi/USB가 바뀌면 start 때 쓴 주소만으로는 실패할 수 있음.
      return <String>[first, ...rest];
    }
    return _activeBases;
  }

  static Future<Map<String, dynamic>?> searchEasyDrug({
    required String itemName,
    int pageNo = 1,
    int numOfRows = 20,
  }) async {
    if (!canCall) return null;
    Object? lastErr;
    final bases = _activeBases;
    for (var i = 0; i < bases.length; i++) {
      final base = bases[i];
      try {
        final uri = Uri.parse('$base/v1/public/easy-drug').replace(
          queryParameters: {
            'itemName': itemName,
            'pageNo': '$pageNo',
            'numOfRows': '$numOfRows',
          },
        );
        final res = await http
            .get(uri)
            .timeout(const Duration(seconds: 8));
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw StateError('easy-drug HTTP ${res.statusCode}: ${res.body}');
        }
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e, st) {
        lastErr = e;
        if (_shouldRetryBffOn(e, i, bases.length)) continue;
        Error.throwWithStackTrace(e, st);
      }
    }
    throw lastErr ?? StateError('easy-drug: BFF 요청 실패 ($_basesDebug)');
  }

  static Future<Map<String, dynamic>?> tilkoHiraSimpleAuth(
    Map<String, dynamic> body,
  ) async {
    if (!canCall) return null;
    final encoded = jsonEncode(body);
    Object? lastErr;
    final bases = _activeBases;
    for (var i = 0; i < bases.length; i++) {
      final base = bases[i];
      try {
        final uri = Uri.parse('$base/v1/tilko/hira-simple-auth');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: encoded,
            )
            .timeout(const Duration(seconds: 12));
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final detail = _flowHttpErrorDetail(res.statusCode, res.body);
          throw StateError('tilko HTTP ${res.statusCode}: $detail');
        }
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e, st) {
        lastErr = e;
        if (_shouldRetryBffOn(e, i, bases.length)) continue;
        Error.throwWithStackTrace(e, st);
      }
    }
    throw lastErr ?? StateError('tilko: BFF 요청 실패 ($_basesDebug)');
  }

  /// 틸코 간편인증 후 NHIS 진료·투약 정보 — BFF `POST /v1/flow/tilko-hira-medications`.
  ///
  /// [flowExtras] 는 BFF로 함께 보내는 부가 필드(레거시 호환)입니다.
  static Future<Map<String, dynamic>?> flowTilkoHiraMedications({
    required Map<String, dynamic> tilko,
    Map<String, dynamic>? flowExtras,
    String phase = 'full',
    Map<String, dynamic>? tilkoSimpleAuth,
    String? authChannel,
  }) async {
    if (!canCall) return null;
    final bases = _basesForFlowPhase(phase);
    if (bases.isEmpty) return null;
    if (phase == 'start') {
      clearLastSuccessfulFlowBase();
    }
    final extras = flowExtras ?? <String, dynamic>{};
    final payload = <String, dynamic>{
      'tilko': tilko,
      'flow_extras': extras,
      'phase': phase,
    };
    if (tilkoSimpleAuth != null) {
      payload['tilko_simple_auth'] = tilkoSimpleAuth;
    }
    if (authChannel != null && authChannel.trim().isNotEmpty) {
      payload['auth_channel'] = authChannel.trim();
    }
    final body = jsonEncode(payload);
    // PASS continue: BFF logincheck 폴링(~45×1.5초) + 틸코 HTTP — [kLink26BffFlowContinueHttpTimeout].
    final timeout = switch (phase) {
      'start' => const Duration(seconds: 45),
      'continue' => kLink26BffFlowContinueHttpTimeout,
      _ => kLink26BffFlowContinueHttpTimeout,
    };
    Object? lastErr;
    for (var i = 0; i < bases.length; i++) {
      final base = bases[i];
      try {
        final uri = Uri.parse('$base/v1/flow/tilko-hira-medications');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final detail = _flowHttpErrorDetail(res.statusCode, res.body);
          throw StateError('flow HTTP ${res.statusCode}: $detail');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        _lastSuccessfulFlowBase = base;
        if (kDebugMode) {
          debugPrint('Link26BFF: flow $phase OK via $base');
        }
        return decoded;
      } catch (e, st) {
        lastErr = e;
        if (kDebugMode) {
          debugPrint('Link26BFF: flow $phase 실패 ($base) — $e');
        }
        final retryTimeout = phase != 'continue';
        if (_shouldRetryBffOn(
          e,
          i,
          bases.length,
          allowTimeoutRetry: retryTimeout,
        )) {
          continue;
        }
        Error.throwWithStackTrace(e, st);
      }
    }
    throw lastErr ??
        StateError('flow: BFF 요청 실패 (phase=$phase, tried=$_basesDebug)');
  }

  /// BFF가 HTTP 200 + `ok:false` 로 준 `hint_ko` / `detail` 을 스낵바에 넣기 전에 가공합니다.
  static String polishFlowUserMessage(String msg) => _rewriteTilkoEnvHint(msg);
}
