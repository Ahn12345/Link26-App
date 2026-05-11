import 'dart:convert';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_medications_client.dart';
import 'package:link26_app/integrations/nhis/nhis_mock_payloads.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

/// AI 채팅 1·2차 분석용: 건강보험 복약 API(BFF) JSON 스냅샷.
abstract final class NhisChatContext {
  static Future<String> fetchMedicationsSnapshot() async {
    if (NhisRuntimeConfig.useMock) {
      return '${NhisMockPayloads.medicationsJson}\n{"meta":{"source":"nhis_mock"}}';
    }

    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      final cached = await NhisMedicineCacheStore.loadMedicines();
      if (cached.isEmpty) {
        return '(NHIS_BASE_URL 미설정 · 로컬 복약 캐시 없음)';
      }
      return jsonEncode({
        'items': cached.map((m) => m.toJson()).toList(),
        'meta': {'source': 'local_cache_only'},
      });
    }

    var phone = await AuthSession.activePhoneDigits();
    phone ??= await UserLocalRepository.singleUserPhoneDigits();
    if (phone == null || phone.length < 10) {
      final cached = await NhisMedicineCacheStore.loadMedicines();
      if (cached.isEmpty) {
        return '(로그인 전화번호 없음 · 건보 API 호출 생략)';
      }
      return jsonEncode({
        'items': cached.map((m) => m.toJson()).toList(),
        'meta': {'source': 'local_cache_only_no_phone'},
      });
    }

    final user = await UserLocalRepository.findUserByPhone(phone);
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
    return (result as Success<String>).data;
  }

  /// 로컬 캐시 약 이름만 짧게 (프롬프트 보조).
  static Future<String> cachedMedicineNamesSummary({int maxNames = 28}) async {
    final cached = await NhisMedicineCacheStore.loadMedicines();
    if (cached.isEmpty) return '(로컬 복약 이름 없음)';
    return cached.take(maxNames).map((m) => m.name.trim()).join(', ');
  }
}
