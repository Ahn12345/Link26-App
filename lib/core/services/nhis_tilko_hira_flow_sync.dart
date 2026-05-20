import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/codef_flow_connected_id_parse.dart';
import 'package:link26_app/core/services/link26_bff_reachability.dart';
import 'package:link26_app/core/services/link26_lan_bff_discovery.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/codef/codef_medication_mapper.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/tilko/tilko_env.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';
import 'package:link26_app/integrations/tilko/tilko_pass_launch.dart';
import 'package:link26_app/integrations/tilko/tilko_rrn_fields.dart';
import 'package:link26_app/models/medicine.dart';

/// 로그인/가입 직후: BFF `POST /v1/flow/tilko-hira-medications` 로
/// 틸코 공단 간편인증 → NHIS 진료·투약 정보 조회 → 로컬 복약 반영.
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
    String? birthDateYmd,
    String? codefConnectedId,
  }) async {
    if (NhisRuntimeConfig.useMock) {
      if (kDebugMode) {
        debugPrint('Tilko→HIRA: NHIS_USE_MOCK — 플로우 생략');
      }
      return null;
    }

    if (!kIsWeb &&
        NhisRuntimeConfig.lanAutoDiscoverEnabled &&
        !Link26BffReachability.recentlyAllUnreachable) {
      final more = await Link26LanBffDiscovery.discoverOnce(
        listenFor: const Duration(milliseconds: 1500),
      );
      NhisRuntimeConfig.mergeLanDiscoveredBases(more);
      await NhisRuntimeConfig.reorderLanDiscoveredForCurrentDevice();
    }

    if (!Link26BffIntegrationsClient.canCall) {
      if (kDebugMode) {
        debugPrint('Tilko→HIRA: NHIS_BASE_URL 없음 — 플로우 생략');
      }
      return null;
    }

    final birthFromDb = birthDateYmd?.replaceAll(RegExp(r'\D'), '') ?? '';
    final birth = birthFromDb.length == 8
        ? birthFromDb
        : TilkoRrnFields.birthYmdFromRrn(residentRegistrationDigits13.trim());
    if (birth == null || birth.length != 8) {
      return const NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.failed,
        detail: '생년월일(YYYYMMDD)이 없습니다. 회원가입 시 생년월일을 입력했는지 확인하세요.',
      );
    }

    final flowExtras = <String, dynamic>{};
    final cid = codefConnectedId?.trim();
    if (cid != null && cid.isNotEmpty) {
      flowExtras['connectedId'] = cid;
    }
    if (gender.trim().isNotEmpty) {
      flowExtras['gender'] = gender.trim();
    }

    try {
      final tilkoBody = tilkoPrepareSimpleAuthRequestMap({
        'PrivateAuthType': TilkoEnv.privateAuthTypePlain,
        'UserName': displayName.trim(),
        'BirthDate': birth,
        'UserCellphoneNumber': _tilkoCellphone(phoneDigits),
        'IdentityNumber': residentRegistrationDigits13.trim(),
      });
      final res = await _callTilkoHiraFlow(
        tilkoBody: tilkoBody,
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
        final msg = Link26BffIntegrationsClient.polishFlowUserMessage(
          (hint is String && hint.trim().isNotEmpty)
              ? hint.trim()
              : (detail is String && detail.trim().isNotEmpty)
                  ? detail.trim()
                  : 'BFF 틸코·건강보험공단(NHIS) 연동에 실패했습니다.',
        );
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
      if (e is TimeoutException && TilkoEnv.isPassAuth) {
        if (kDebugMode) {
          debugPrint(
            'Tilko→HIRA: BFF phase=continue 시간 초과 — PASS 앱·문자에서 승인 후 다시 시도 ($e)',
          );
        }
        return const NhisMedicinesSyncOutcome(
          result: NhisMedicinesSyncResult.failed,
          detail:
              'PASS 인증 대기 시간이 초과되었습니다. '
              '통신사 PASS 앱(또는 문자·나의 인증내역)에서 승인한 뒤 「심평원에서 불러오기」를 다시 눌러 주세요. '
              'PC BFF는 켜 둔 채로 시도하세요.',
        );
      }
      if (link26ErrorLooksLikeUnreachableHost(e)) {
        if (kDebugMode) {
          debugPrint('Tilko→HIRA: BFF 연결 불가 — $e');
          final base = NhisRuntimeConfig.baseUrlCandidates.join(', ');
          debugPrint(
            'Link26 BFF 연결 점검(상세):\n'
            '• PC: `dart run tool/link26_bff.dart` 실행, 콘솔 포트 = 앱 NHIS_BASE_URL 포트\n'
            '• 앱 후보 주소: $base\n'
            '• PC `ipconfig` IPv4 = NHIS_BASE_URL IP, 폰·PC 동일 Wi‑Fi\n'
            '• 여러 IP면 dotenv NHIS_BASE_URL에 쉼표로 나열\n'
            '• Windows 방화벽 인바운드(예: 8787)\n'
            '• USB만: `adb reverse tcp:8787 tcp:8787` 후 http://127.0.0.1:8787',
          );
        }
        final short = kReleaseMode
            ? '건강·복약 서버(BFF)에 연결하지 못했습니다. '
                '인터넷과 운영 주소(NHIS_PRODUCTION_BASE_URL·원격 설정)를 확인해 주세요.'
            : 'PC BFF에 연결하지 못했습니다. '
                'BFF 실행·Wi‑Fi·포트·방화벽을 확인해 주세요. '
                '(자세한 점검 항목은 디버그 콘솔 로그를 참고하세요.)';
        return NhisMedicinesSyncOutcome(
          result: NhisMedicinesSyncResult.failed,
          detail: short,
        );
      }
      debugPrint('Tilko→HIRA: $e\n$st');
      return NhisMedicinesSyncOutcome(
        result: NhisMedicinesSyncResult.failed,
        detail: Link26BffIntegrationsClient.sanitizeIntegrationErrorMessage('$e'),
      );
    }
  }

  /// 틸코→BFF(NHIS) 플로우만 사용합니다. 예전 CODEF·스텁용 `GET /v1/medications` 보완 호출은 제거했습니다.
  static Future<NhisMedicinesSyncOutcome?> runTilkoThenHiraWithMedicationsFallback({
    required String displayName,
    required String phoneDigits,
    required String gender,
    required String residentRegistrationDigits13,
    String? birthDateYmd,
    String? codefConnectedId,
  }) async {
    final first = await runTilkoThenHira(
      displayName: displayName,
      phoneDigits: phoneDigits,
      gender: gender,
      residentRegistrationDigits13: residentRegistrationDigits13,
      birthDateYmd: birthDateYmd,
      codefConnectedId: codefConnectedId,
    );
    if (first == null) return null;
    if (NhisRuntimeConfig.useMock) return first;
    if (!Link26BffIntegrationsClient.canCall) return first;
    return first;
  }

  /// PASS: `phase=start` → PASS 앱 인증 화면 → `phase=continue` 폴링.
  /// 그 외 채널: 기존 단일 BFF 호출.
  static Future<Map<String, dynamic>?> _callTilkoHiraFlow({
    required Map<String, dynamic> tilkoBody,
    Map<String, dynamic>? flowExtras,
  }) async {
    if (!TilkoEnv.isPassAuth) {
      return Link26BffIntegrationsClient.flowTilkoHiraMedications(
        tilko: tilkoBody,
        flowExtras: flowExtras,
      );
    }

    final start = await Link26BffIntegrationsClient.flowTilkoHiraMedications(
      tilko: tilkoBody,
      flowExtras: flowExtras,
      phase: 'start',
    );
    if (start == null) return null;
    if (start['ok'] != true) return start;

    final urisRaw = start['pass_launch_uris'];
    final uris = urisRaw is List
        ? urisRaw.map((e) => '$e').where((s) => s.trim().isNotEmpty).toList()
        : TilkoPassLaunch.extractLaunchUrisFromTilko(start['tilko_simple_auth']);

    final opened = await TilkoPassLaunch.openAuthScreen(tilkoUris: uris);
    if (kDebugMode) {
      debugPrint(
        'Tilko→HIRA: PASS 앱 실행 ${opened ? "성공" : "실패"} (URL ${uris.length}건)',
      );
      if (uris.isEmpty) {
        final hint = start['hint_ko'];
        if (hint is String && hint.trim().isNotEmpty) {
          debugPrint('Tilko→HIRA: $hint');
        }
      }
    }
    // logincheck 폴링(~3분) 전에 PASS 화면으로 전환할 시간.
    await Future<void>.delayed(const Duration(seconds: 8));

    final lifted = start['tilko_simple_auth'];
    if (lifted is! Map) return start;

    return Link26BffIntegrationsClient.flowTilkoHiraMedications(
      tilko: tilkoBody,
      flowExtras: flowExtras,
      phase: 'continue',
      tilkoSimpleAuth: Map<String, dynamic>.from(
        lifted.map((k, v) => MapEntry('$k', v)),
      ),
      authChannel: start['auth_channel'] as String?,
    );
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
