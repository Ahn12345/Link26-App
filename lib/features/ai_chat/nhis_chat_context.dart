import 'dart:async';
import 'dart:convert';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_medications_client.dart';
import 'package:link26_app/integrations/nhis/nhis_mock_payloads.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

/// AI 채팅 1·2차 분석용: 건강보험 복약 API(BFF) JSON 스냅샷.
abstract final class NhisChatContext {
  /// [timeLimit]이 있으면 그 안에 응답이 없을 때 메시지로 대체합니다(AI 채팅이 무한 대기하지 않도록).
  static Future<String> fetchMedicationsSnapshot({
    Duration? timeLimit,
  }) async {
    Future<String> run() async {
      if (NhisRuntimeConfig.useMock) {
        return '${NhisMockPayloads.medicationsJson}\n{"meta":{"source":"nhis_mock"}}';
      }

      final cached = await NhisMedicineCacheStore.loadMedicines();
      if (cached.isNotEmpty) {
        return jsonEncode({
          'items': cached.map((m) => m.toJson()).toList(),
          'meta': {'source': 'local_cache'},
        });
      }

      if (NhisRuntimeConfig.baseUrl.isEmpty) {
        return '(NHIS_BASE_URL 미설정 · 로컬 복약 캐시 없음 — 홈에서 「심평원에서 불러오기」)';
      }

      final user = await UserLocalRepository.loadSignedInUserRecord();
      final phone = user?.phoneDigits.replaceAll(RegExp(r'\D'), '') ?? '';
      if (phone.length < 10) {
        return '(로그인 전화번호 없음 · 건보 API 호출 생략 — 홈에서 「심평원에서 불러오기」)';
      }

      var cid = user?.codefConnectedId?.trim();
      if (cid == null || cid.isEmpty) {
        cid = NhisRuntimeConfig.codefConnectedIdForMedications;
      }

      final client = NhisMedicationsClient();
      final result = await client.fetchMedicationsRaw(
        phoneDigits: phone,
        displayName: user?.displayName,
        gender: user?.gender,
        connectedId: cid,
      );

      if (result is Failure<String>) {
        return '건강보험 복약 API 오류: ${nhisHttpUserMessage(result.error)}';
      }
      final raw = (result as Success<String>).data;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final meta = decoded['meta'];
          final src = meta is Map ? '${meta['source']}' : '';
          if (src == 'link26-bff-dart-stub' || src == 'link26-bff-dart') {
            return '(BFF 데모 스텁 — 실제 복약은 홈 「심평원에서 불러오기」로 연동)';
          }
        }
      } catch (_) {}
      return raw;
    }

    if (timeLimit == null) return run();
    return run().timeout(
      timeLimit,
      onTimeout: () =>
          '건강보험 복약 API: ${timeLimit.inSeconds}초 내 응답 없음. '
          '폰의 NHIS_BASE_URL이 PC 주소(예: http://192.168.x.x:8787)인지, '
          '같은 Wi‑Fi인지, Windows 방화벽에서 해당 포트가 허용됐는지 확인하세요.',
    );
  }

  /// 로컬 캐시 약 이름만 짧게 (프롬프트 보조).
  static Future<String> cachedMedicineNamesSummary({int maxNames = 28}) async {
    final cached = await NhisMedicineCacheStore.loadMedicines();
    if (cached.isEmpty) return '(로컬 복약 이름 없음)';
    return cached.take(maxNames).map((m) => m.name.trim()).join(', ');
  }
}
