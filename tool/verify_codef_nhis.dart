// CODEF OAuth + NHIS 진료·투약 상품 URL(후보 순회) 내부 검증.
// 실행: 프로젝트 루트에서  dart run tool/verify_codef_nhis.dart

// ignore_for_file: avoid_print
import 'dart:convert';

import 'link26_bff_codef.dart';

String _truncate(String s, [int max = 400]) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

void main() async {
  print('[verify] loadBffDotEnv');
  final env = loadBffDotEnv();

  final health = await codefHealthProbe(env);
  print('[verify] codefHealthProbe: $health');
  if (health['token'] != 'ok') {
    print('[verify] ABORT: OAuth/token 실패');
    return;
  }

  print('[verify] codefNhisTreatmentProductRaw (최소 본문: organization·간편인증 타입 등)');
  final nhisBody = codefNhisTreatmentProbeBody(env);
  print('[verify] body keys=${nhisBody.keys.toList()}');
  try {
    final raw = await codefNhisTreatmentProductRaw(
      env: env,
      bearer: await bffCodefBearer(env),
      body: nhisBody,
    );
    Map<String, dynamic>? map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {}
    final res = map?['result'];
    final code = res is Map ? '${res['code']}' : '?';
    final msg = res is Map ? '${res['message']}' : '';
    print('[verify] OK: HTTP 상품 응답 수신 result.code=$code msg=${_truncate(msg, 120)}');
    final hint = bffCodefNhisTreatResultHintKo(code, msg);
    if (hint != null) {
      print('[verify] hint: $hint');
    }
    print('[verify] body(head)=${_truncate(raw, 280)}');
  } catch (e, st) {
    print('[verify] FAIL: $e');
    print(_truncate('$st', 500));
  }
}
