import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

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
        return hint.trim();
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
        return d;
      }
    }
  } catch (_) {}
  if (body.trim().isNotEmpty) return body.trim();
  return 'HTTP $statusCode';
}

/// 이 레포의 **Dart BFF**(`dart run tool/link26_bff.dart`)에만 붙입니다.
///
/// `NHIS_BASE_URL`은 위 BFF의 베이스(예: `http://10.0.2.2:8787`)여야 하며,
/// 다른 백엔드(FastAPI 등) URL을 넣으면 경로·오류 형식이 맞지 않을 수 있습니다.
///
/// 틸코 API 키 등은 BFF 루트 `.env`에 두고, 앱은 NHIS_BASE_URL만 알면 됩니다.
///
/// [NhisRuntimeConfig.useMock] 은 가입·로그인·복약 동기화용 목 데이터에만 쓰이고,
/// 여기 BFF 프록시(e약은요·틸코·플로우)는 막지 않습니다.
abstract final class Link26BffIntegrationsClient {
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
        return _flowHttpErrorDetail(code, rest);
      }
      if (rest.isNotEmpty) {
        return rest;
      }
    }
    return t.length > 420 ? '${t.substring(0, 420)}…' : t;
  }

  static String get _base {
    final b = NhisRuntimeConfig.baseUrl.trim();
    if (b.isEmpty) return '';
    return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
  }

  static bool get canCall => _base.isNotEmpty;

  static Future<Map<String, dynamic>?> searchEasyDrug({
    required String itemName,
    int pageNo = 1,
    int numOfRows = 20,
  }) async {
    if (!canCall) return null;
    final uri = Uri.parse('$_base/v1/public/easy-drug').replace(
      queryParameters: {
        'itemName': itemName,
        'pageNo': '$pageNo',
        'numOfRows': '$numOfRows',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('easy-drug HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> tilkoHiraSimpleAuth(
    Map<String, dynamic> body,
  ) async {
    if (!canCall) return null;
    final uri = Uri.parse('$_base/v1/tilko/hira-simple-auth');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final detail = _flowHttpErrorDetail(res.statusCode, res.body);
      throw StateError('tilko HTTP ${res.statusCode}: $detail');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 틸코 간편인증 후 심평원 **내가 먹는 약**(hiraa050300000100) — BFF `POST /v1/flow/tilko-hira-medications`.
  ///
  /// [flowExtras] 는 BFF로 함께 보내는 부가 필드(예: 레거시 `connectedId`)입니다.
  static Future<Map<String, dynamic>?> flowTilkoHiraMedications({
    required Map<String, dynamic> tilko,
    Map<String, dynamic>? flowExtras,
  }) async {
    if (!canCall) return null;
    final uri = Uri.parse('$_base/v1/flow/tilko-hira-medications');
    final extras = flowExtras ?? <String, dynamic>{};
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tilko': tilko,
        'flow_extras': extras,
        // 구 BFF·문서 호환: 동일 맵을 codef_payload 키로도 전달
        'codef_payload': extras,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final detail = _flowHttpErrorDetail(res.statusCode, res.body);
      throw StateError('flow HTTP ${res.statusCode}: $detail');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
