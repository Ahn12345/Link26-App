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

  print('[verify] fetchMedicationsFromCodef (앱 GET /v1/medications 와 동일한 CODEF 호출)');
  final phoneMed = (env['CODEF_VERIFY_PLACEHOLDER_PHONE'] ?? '01012345678')
      .replaceAll(RegExp(r'\D'), '');
  final phoneOk = phoneMed.length >= 10 ? phoneMed : '01012345678';
  try {
    final med = await fetchMedicationsFromCodef(
      env: env,
      phoneDigits: phoneOk,
      displayName: (env['CODEF_VERIFY_PLACEHOLDER_NAME'] ?? '').trim(),
      gender: '',
    );
    if (med == null) {
      print(
        '[verify] medications: null — BFF_USE_CODEF_FOR_MEDICATIONS 또는 클라이언트·경로 비어 있음',
      );
      return;
    }
    final meta = med['meta'];
    final items = med['items'];
    final n = items is List ? items.length : -1;
    print('[verify] medications: items.count=$n meta=$meta');
    if (n > 0 && items is List) {
      final first = items.first;
      if (first is Map) {
        print('[verify] medications: first.name=${first['name']}');
      }
    }
  } catch (e, st) {
    print('[verify] medications FAIL: $e');
    print(_truncate('$st', 500));
  }
}
