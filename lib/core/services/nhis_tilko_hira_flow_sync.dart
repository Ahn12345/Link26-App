import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/codef_flow_connected_id_parse.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/codef/codef_medication_mapper.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/tilko/tilko_env.dart';
import 'package:link26_app/integrations/tilko/tilko_rrn_fields.dart';
import 'package:link26_app/models/medicine.dart';

/// 로그인/가입 직후: BFF `POST /v1/flow/tilko-hira-medications` 로
/// 틸코 간편인증 → 심평원 **내가 먹는 약**(hiraa050300000100) 조회 → 로컬 복약 반영.
abstract final class NhisTilkoHiraFlowSync {
  static String _tilkoCellphone(String phoneDigits) {
    final d = phoneDigits.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11 && d.startsWith('010')) {
      return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
    }
    if (d.length == 10 && d.startsWith('02')) {
      return '${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}';
    }
    return d;
  }

  static Future<NhisMedicinesSyncOutcome?> runTilkoThenHira({
    required String displayName,
    required String phoneDigits,
    required String gender,
    required String residentRegistrationDigits13,
    String? codefConnectedId,
  }) async {
    try {
      await dotenv.load(fileName: 'assets/env/dotenv');
    } catch (_) {}

    if (NhisRuntimeConfig.useMock) {
      if (kDebugMode) {
        debugPrint('Tilko→HIRA: NHIS_USE_MOCK — 플로우 생략');
      }
      return null;
    }

    if (!Link26BffIntegrationsClient.canCall) {
      if (kDebugMode) {
        debugPrint('Tilko→HIRA: NHIS_BASE_URL 없음 — 플로우 생략');
      }
      return null;
    }

    final birth =
        TilkoRrnFields.birthYmdFromRrn(residentRegistrationDigits13.trim());
    if (birth == null) {
      return const NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.failed,
        detail: '주민등록번호에서 생년월일을 해석하지 못했습니다.',
      );
    }

    final privateAuthType = TilkoEnv.privateAuthType;
    final flowExtras = <String, dynamic>{};
    final cid = codefConnectedId?.trim();
    if (cid != null && cid.isNotEmpty) {
      flowExtras['connectedId'] = cid;
    }
    if (gender.trim().isNotEmpty) {
      flowExtras['gender'] = gender.trim();
    }

    try {
      final res = await Link26BffIntegrationsClient.flowTilkoHiraMedications(
        tilko: {
          'PrivateAuthType':
              privateAuthType.isEmpty ? 'KAKAO' : privateAuthType,
          'UserName': displayName.trim(),
          'BirthDate': birth,
          'UserCellphoneNumber': _tilkoCellphone(phoneDigits),
          'IdentityNumber': residentRegistrationDigits13.trim(),
        },
        flowExtras: flowExtras.isEmpty ? null : flowExtras,
      );

      if (res == null) {
        return const NhisMedicinesSyncOutcome(
          result: NhisMedicinesSyncResult.skipped,
        );
      }

      final ok = res['ok'] == true;
      if (!ok) {
        final hint = res['hint_ko'];
        final detail = res['detail'];
        final msg = (hint is String && hint.trim().isNotEmpty)
            ? hint.trim()
            : (detail is String && detail.trim().isNotEmpty)
                ? detail.trim()
                : 'BFF 틸코·심평원 연동에 실패했습니다.';
        return NhisMedicinesSyncOutcome(
          result: NhisMedicinesSyncResult.failed,
          detail: msg,
        );
      }

      await _persistConnectedIdFromFlowResponse(phoneDigits, res);

      Map<String, dynamic>? metaMap;
      final meta = res['meta'];
      if (meta is Map) {
        metaMap = Map<String, dynamic>.from(
          meta.map((k, v) => MapEntry('$k', v)),
        );
      }
      final source = metaMap?['source'] as String?;

      if (source == 'tilko_only') {
        return NhisMedicinesSyncOutcome(
          result: NhisMedicinesSyncResult.success,
          remoteItemCount: 0,
          metaSource: source,
          metaNote: metaMap?['notice'] as String?,
        );
      }

      final itemsRaw = res['items'];
      final list = itemsRaw is List ? itemsRaw : const <dynamic>[];
      final medicines = <Medicine>[];
      for (final e in list) {
        if (e is Map) {
          medicines.add(
            Medicine.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }

      if (medicines.isEmpty) {
        dynamic rootRaw = res['hira_medications'];
        if (rootRaw is! Map) rootRaw = res['nhis_treatment_injection'];
        if (rootRaw is Map) {
          final rootMap = Map<String, dynamic>.from(
            rootRaw.map((k, v) => MapEntry('$k', v)),
          );
          for (final row in codefRootToMedicationItems(rootMap)) {
            medicines.add(Medicine.fromJson(row));
          }
        }
      }

      final metaNoteRaw = metaMap?['note'] ?? metaMap?['notice'];
      final metaNoteStr = metaNoteRaw is String ? metaNoteRaw.trim() : '';
      return NhisMedicinesSync.applyRemoteMedicines(
        medicines: medicines,
        metaSource: source,
        codefResultCode: metaMap?['codefResultCode'] as String?,
        codefResultMessage: metaMap?['codefResultMessage'] as String?,
        metaNote: metaNoteStr.isEmpty ? null : metaNoteStr,
      );
    } catch (e, st) {
      if (link26ErrorLooksLikeUnreachableHost(e)) {
        if (kDebugMode) {
          debugPrint('Tilko→HIRA: BFF 연결 불가 — $e');
        }
        final base = NhisRuntimeConfig.baseUrl.trim();
        return NhisMedicinesSyncOutcome(
          result: NhisMedicinesSyncResult.failed,
          detail:
              '심평원 데이터는 PC에서 돌아가는 BFF를 거칩니다. 지금은 그 BFF에 '
              '연결되지 않았습니다.\n\n'
              '• PC에서 `dart run tool/link26_bff.dart` 실행 후, 콘솔에 나온 **포트**가 '
              '앱 설정($base)의 포트와 같은지 확인하세요.\n'
              '• PC `ipconfig`의 IPv4가 192.168.150.143이 맞는지, 폰과 PC가 **같은 Wi-Fi**인지 확인하세요.\n'
              '• Windows 방화벽에서 해당 포트(예: 8787) **인바운드 허용** 여부를 확인하세요.\n'
              '• USB만 쓸 때: PC에서 `adb reverse tcp:8787 tcp:8787` 후 앱 주소를 '
              '`http://127.0.0.1:8787`로 맞추는 방법도 있습니다.',
        );
      }
      debugPrint('Tilko→HIRA: $e\n$st');
      return NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.failed,
        detail: Link26BffIntegrationsClient.sanitizeIntegrationErrorMessage('$e'),
      );
    }
  }

  /// 틸코→심평원 플로우 후, 약이 0건이면 `/v1/medications` 로 한 번 더 보완합니다(스텁·레거시 GET).
  static Future<NhisMedicinesSyncOutcome?> runTilkoThenHiraWithMedicationsFallback({
    required String displayName,
    required String phoneDigits,
    required String gender,
    required String residentRegistrationDigits13,
    String? codefConnectedId,
  }) async {
    final first = await runTilkoThenHira(
      displayName: displayName,
      phoneDigits: phoneDigits,
      gender: gender,
      residentRegistrationDigits13: residentRegistrationDigits13,
      codefConnectedId: codefConnectedId,
    );
    if (first == null) return null;
    if (NhisRuntimeConfig.useMock) return first;
    if (!Link26BffIntegrationsClient.canCall) return first;

    final tilkoOnly = first.metaSource == 'tilko_only';
    final emptyOk = first.result == NhisMedicinesSyncResult.success &&
        first.remoteItemCount == 0 &&
        !first.isStubDemo;

    if (!tilkoOnly && !emptyOk) return first;

    final second = await NhisMedicinesSync.syncNow(phoneDigits: phoneDigits);
    if (second.remoteItemCount > first.remoteItemCount) {
      return second;
    }
    if (second.metaSource == 'codef' && first.metaSource != 'codef') {
      return second;
    }
    return first;
  }

  static Future<void> _persistConnectedIdFromFlowResponse(
    String phoneDigits,
    Map<String, dynamic> res,
  ) async {
    final p = phoneDigits.replaceAll(RegExp(r'\D'), '');
    if (p.length < 10) return;
    final id = parseConnectedIdFromBffFlowResponse(res);
    if (id == null || id.isEmpty) return;
    await UserLocalRepository.updateCodefConnectedId(p, connectedId: id);
    if (kDebugMode) {
      debugPrint('Tilko→HIRA: connectedId를 로컬 DB에 저장했습니다.');
    }
  }
}
