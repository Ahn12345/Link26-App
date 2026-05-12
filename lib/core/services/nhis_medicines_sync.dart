import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/core/services/dose_reminder_completion_store.dart';
import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_medications_client.dart';
import 'package:link26_app/integrations/nhis/nhis_medications_parser.dart';
import 'package:link26_app/integrations/nhis/nhis_mock_payloads.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/models/medicine.dart';

enum NhisMedicinesSyncResult { skipped, success, failed }

/// [NhisMedicinesSync.syncNow] 결과 — UI 알림용.
class NhisMedicinesSyncOutcome {
  const NhisMedicinesSyncOutcome({
    required this.result,
    this.remoteItemCount = 0,
    this.metaSource,
    this.codefResultCode,
    this.codefResultMessage,
    this.metaNote,
    this.detail,
  });

  final NhisMedicinesSyncResult result;
  final int remoteItemCount;
  final String? metaSource;
  final String? codefResultCode;
  final String? codefResultMessage;
  final String? metaNote;
  final String? detail;

  bool get isStubDemo =>
      metaSource == 'link26-bff-dart-stub' || metaSource == 'link26-bff-dart';

  bool get isCodefError => metaSource == 'codef_error';

  bool get isMissingConnectedId => metaSource == 'codef_missing_connected_id';

  bool get isTilkoCodefNhis => metaSource == 'tilko_codef_nhis';

  bool get showBannerOnBootstrap {
    if (result == NhisMedicinesSyncResult.failed) return true;
    if (result == NhisMedicinesSyncResult.skipped) return true;
    // BFF 스텁으로 성공한 경우 매 부팅 "데모입니다" 스낵바는 생략(로그만).
    if (result == NhisMedicinesSyncResult.success && isStubDemo) return false;
    if (isStubDemo) return true;
    if (isCodefError) return true;
    if (isMissingConnectedId) return true;
    if (metaSource == 'codef' &&
        remoteItemCount == 0 &&
        codefResultCode != null &&
        codefResultCode != 'CF-00000') {
      return true;
    }
    if (metaSource == 'codef' && remoteItemCount == 0) return true;
    if (isTilkoCodefNhis &&
        remoteItemCount == 0 &&
        codefResultCode != null &&
        codefResultCode != 'CF-00000') {
      return true;
    }
    if (isTilkoCodefNhis && remoteItemCount == 0) return true;
    if (metaSource == 'tilko_only' && (metaNote ?? '').trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  String get userMessageKo {
    switch (result) {
      case NhisMedicinesSyncResult.skipped:
        return '복약 동기화를 건너뛰었습니다. NHIS_BASE_URL·설정을 확인하세요.';
      case NhisMedicinesSyncResult.failed:
        return detail ?? '복약 목록을 가져오지 못했습니다.';
      case NhisMedicinesSyncResult.success:
        if (isCodefError) {
          return detail ?? '연동 서버(CODEF) 오류입니다. BFF 로그를 확인하세요.';
        }
        if (isMissingConnectedId) {
          return metaNote ??
              'CODEF 본인 진료·투약 조회를 위해 connectedId가 필요합니다. '
              '설정의 「건강·복약 연동」에서 저장하거나 BFF .env의 CODEF_CONNECTED_ID를 설정하세요.';
        }
        if (isStubDemo) {
          return '지금 보이는 복약 목록은 데모입니다. 실제 본인 데이터는 BFF에서 CODEF(또는 공단) 상품·connectedId·추가인증까지 완료해야 합니다.';
        }
        if (metaSource == 'codef' && remoteItemCount == 0) {
          final c = codefResultCode ?? '';
          final m = codefResultMessage ?? '';
          return '연동 응답은 왔지만 복약 항목이 0건입니다. '
              'CODEF connectedId·상품 경로·추가인증을 확인하세요. ($c ${m.isNotEmpty ? m : ''})';
        }
        if (isTilkoCodefNhis && remoteItemCount == 0) {
          final c = codefResultCode ?? '';
          final m = codefResultMessage ?? '';
          return '틸코 간편인증 후 조회했지만 복약 항목이 0건입니다. '
              'BFF .env의 CODEF 건보 진료·투약 상품 경로·connectedId를 확인하세요. ($c ${m.isNotEmpty ? m : ''})';
        }
        if (metaSource == 'tilko_only' &&
            (metaNote ?? '').trim().isNotEmpty) {
          return metaNote!.trim();
        }
        if (metaNote != null && metaNote!.isNotEmpty) return metaNote!;
        return '복약 $remoteItemCount건을 반영했습니다.';
    }
  }
}

/// BFF 복약 목록을 내려받아 로컬 캐시·약 이름 목록과 병합합니다.
abstract final class NhisMedicinesSync {
  static String _norm(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static Future<NhisMedicinesSyncOutcome> syncNow({
    required String phoneDigits,
  }) async {
    try {
      await dotenv.load(fileName: 'assets/env/dotenv');
    } catch (_) {}

    if (NhisRuntimeConfig.useMock) {
      if (kDebugMode) {
        debugPrint('NHIS medications: 목(mock) 병합 — 네트워크 미사용');
      }
      final fromApi =
          NhisMedicationsParser.parseResponseBody(NhisMockPayloads.medicationsJson);
      await _mergeIntoLocal(fromApi);
      return NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.success,
        remoteItemCount: fromApi.length,
        metaSource: 'mock',
      );
    }

    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('NHIS medications: NHIS_BASE_URL 비어 있음 — skipped');
      }
      return const NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.skipped,
      );
    }

    final user = phoneDigits.isNotEmpty
        ? await UserLocalRepository.findUserByPhone(phoneDigits)
        : null;

    var connectedId = user?.codefConnectedId?.trim();
    if (connectedId == null || connectedId.isEmpty) {
      connectedId = NhisRuntimeConfig.codefConnectedIdForMedications;
    }

    final client = NhisMedicationsClient();
    final result = await client.fetchMedicationsRaw(
      phoneDigits: phoneDigits,
      displayName: user?.displayName,
      gender: user?.gender,
      connectedId: connectedId,
    );

    if (result is Failure<String>) {
      final msg = nhisHttpUserMessage(result.error);
      debugPrint(
        'NHIS medications GET 실패: $msg (base=${NhisRuntimeConfig.baseUrl} path=${NhisRuntimeConfig.medicinesPath})',
      );
      return NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.failed,
        detail: msg,
      );
    }

    final body = (result as Success<String>).data;
    final meta = _parseResponseMeta(body);
    final fromApi = NhisMedicationsParser.parseResponseBody(body);
    final src = meta?['source'] as String?;
    if (isAuthoritativeMedicationsMetaSource(src)) {
      await _replaceLocalWithRemote(fromApi);
      await DoseReminderCompletionStore.clearAll();
    } else {
      await _mergeIntoLocal(fromApi);
    }

    return NhisMedicinesSyncOutcome(
      result: NhisMedicinesSyncResult.success,
      remoteItemCount: fromApi.length,
      metaSource: meta?['source'] as String?,
      codefResultCode: meta?['codefResultCode'] as String?,
      codefResultMessage: meta?['codefResultMessage'] as String?,
      metaNote: meta?['note'] as String?,
    );
  }

  /// 틸코→CODEF(건보) 플로우 등에서 이미 파싱된 목록을 반영할 때 사용합니다.
  static Future<NhisMedicinesSyncOutcome> applyRemoteMedicines({
    required List<Medicine> medicines,
    String? metaSource,
    String? codefResultCode,
    String? codefResultMessage,
    String? metaNote,
  }) async {
    if (isAuthoritativeMedicationsMetaSource(metaSource)) {
      await _replaceLocalWithRemote(medicines);
      await DoseReminderCompletionStore.clearAll();
    } else {
      await _mergeIntoLocal(medicines);
    }
    return NhisMedicinesSyncOutcome(
      result: NhisMedicinesSyncResult.success,
      remoteItemCount: medicines.length,
      metaSource: metaSource,
      codefResultCode: codefResultCode,
      codefResultMessage: codefResultMessage,
      metaNote: metaNote,
    );
  }

  /// [codef]·[tilko_codef_nhis] 응답은 로컬 데모·수동 목록을 덮어씁니다.
  static bool isAuthoritativeMedicationsMetaSource(String? source) {
    final s = source?.trim() ?? '';
    return s == 'codef' || s == 'tilko_codef_nhis';
  }

  static Map<String, dynamic>? _parseResponseMeta(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final m = decoded['meta'];
      if (m is! Map) return null;
      return Map<String, dynamic>.from(
        m.map((k, v) => MapEntry('$k', v)),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _replaceLocalWithRemote(List<Medicine> fromApi) async {
    await NhisMedicineCacheStore.saveMedicines(fromApi);
    final names = fromApi
        .map((m) => m.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    await LocalMedicineListStore.save(names);
  }

  static Future<void> _mergeIntoLocal(List<Medicine> fromApi) async {
    final cached = await NhisMedicineCacheStore.loadMedicines();
    final manualNames = await LocalMedicineListStore.load();

    final byName = <String, Medicine>{};
    for (final m in cached) {
      final k = _norm(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final m in fromApi) {
      final k = _norm(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final n in manualNames) {
      final k = _norm(n);
      if (k.isEmpty) continue;
      byName.putIfAbsent(
        k,
        () => Medicine(name: n.trim(), dose: '-', frequency: '-', time: '-'),
      );
    }

    final merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    await NhisMedicineCacheStore.saveMedicines(merged);

    for (final m in merged) {
      await LocalMedicineListStore.add(m.name);
    }
  }
}
