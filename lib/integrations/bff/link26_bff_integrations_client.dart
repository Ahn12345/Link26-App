import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

/// NHIS/BFF(`NHIS_BASE_URL`)에 붙는 연동 API — 틸코·공공데이터·CODEF 플로우.
///
/// 키는 BFF `.env`에 두고 앱은 URL만 알면 됩니다.
///
/// [NhisRuntimeConfig.useMock] 은 가입·로그인·복약 동기화용 목 데이터에만 쓰이고,
/// 여기 BFF 프록시( e약은요·틸코·플로우 )는 막지 않습니다.
abstract final class Link26BffIntegrationsClient {
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
      throw StateError('tilko HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> flowTilkoCodefTreatment({
    required Map<String, dynamic> tilko,
    Map<String, dynamic>? codefPayload,
  }) async {
    if (!canCall) return null;
    final uri = Uri.parse('$_base/v1/flow/tilko-codef-treatment');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tilko': tilko,
        'codef_payload': codefPayload ?? <String, dynamic>{},
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      var detail = res.body;
      try {
        final m = jsonDecode(res.body);
        if (m is Map) {
          final h = m['hint_ko'];
          if (h is String && h.trim().isNotEmpty) {
            detail = h.trim();
          }
        }
      } catch (_) {}
      throw StateError('flow HTTP ${res.statusCode}: $detail');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
