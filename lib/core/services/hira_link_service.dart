import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:link26_app/core/database/home_notification_repository.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/core/services/nhis_tilko_hira_flow_sync.dart';
import 'package:link26_app/features/auth/signup/signup_validators.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 가입·로그인·홈에서 틸코 간편인증 → BFF 심평원 복약(hiraa050300000100) 조회.
abstract final class HiraLinkService {
  /// 회원가입 직후 — 주민번호는 이미 입력된 값으로 한 번만 BFF 플로우에 사용합니다.
  static Future<void> afterRegistration({
    required BuildContext context,
    required String displayName,
    required String phoneDigits,
    required String gender,
    required String residentRegistrationDigits13,
    String? codefConnectedId,
  }) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '틸코·건강보험 연동 중입니다. 휴대폰에서 카카오 간편인증 알림을 '
            '완료한 뒤 최대 약 2분 기다려 주세요.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }
    final out = await NhisTilkoHiraFlowSync.runTilkoThenHiraWithMedicationsFallback(
      displayName: displayName,
      phoneDigits: phoneDigits,
      gender: gender,
      residentRegistrationDigits13: residentRegistrationDigits13,
      codefConnectedId: codefConnectedId,
    );
    if (!context.mounted || out == null) return;
    if (out.result == NhisMedicinesSyncResult.failed ||
        out.showBannerOnBootstrap) {
      final msg = out.userMessageKo.trim();
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  /// 로그인 직후 — 기기에 주민번호를 저장하지 않습니다.
  ///
  /// 로컬 DB에 `codefConnectedId`(이전 틸코·BFF 연동)가 있으면 [NhisMedicinesSync.syncNow]로
  /// 복약 목록을 먼저 받아 **주민번호 입력 없이** 연동을 시도합니다(기획서 「2번째: DB에 정보 있음」).
  /// 그렇지 않거나 자동 동기화가 경고·실패면, 기존처럼 주민번호 입력 후 틸코·심평원 플로우를 띄웁니다.
  static Future<void> afterLogin({
    required BuildContext context,
    required LocalUserRecord user,
  }) async {
    if (!context.mounted) return;

    if (NhisRuntimeConfig.useMock || !Link26BffIntegrationsClient.canCall) {
      if (kDebugMode) {
        debugPrint(
          'HIRA: 로그인 직후 연동 생략 (mock 또는 NHIS_BASE_URL 없음)',
        );
      }
      return;
    }

    final cid = user.codefConnectedId?.trim();
    if (cid != null && cid.isNotEmpty) {
      final auto = await NhisMedicinesSync.syncNow(
        phoneDigits: user.phoneDigits,
      );
      if (!context.mounted) return;
      if (auto.result == NhisMedicinesSyncResult.success &&
          !auto.showBannerOnBootstrap) {
        if (kDebugMode) {
          debugPrint(
            'HIRA: connectedId 기반 복약 동기화 완료 — 주민번호 다이얼로그 생략',
          );
        }
        return;
      }
    }

    await promptRrnAndSyncHiraMedications(
      context: context,
      user: user,
      announceSuccess: false,
    );
  }

  /// 홈·기타: 주민번호 입력 후 심평원 복약(BFF) 동기화.
  ///
  /// 성공 시 [announceSuccess] 가 true 이면 간단한 완료 스낵바를 띄웁니다.
  static Future<NhisMedicinesSyncOutcome?> promptRrnAndSyncHiraMedications({
    required BuildContext context,
    required LocalUserRecord user,
    bool announceSuccess = false,
  }) async {
    if (!context.mounted) return null;

    if (NhisRuntimeConfig.useMock || !Link26BffIntegrationsClient.canCall) {
      if (context.mounted) {
        final msg = NhisRuntimeConfig.useMock
            ? 'NHIS_USE_MOCK=true 입니다. .env에서 false 후 앱을 다시 빌드하세요.'
            : 'BFF 주소(NHIS_BASE_URL)가 없습니다. '
                'PC에서 BFF 실행·USB면 adb reverse tcp:8787 후 앱 재빌드하세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
        );
      }
      return null;
    }

    final l10n = AppLocalizations.of(context);
    final submitted = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TilkoNhisRrnDialog(l10n: l10n),
    );

    if (submitted == null || submitted.trim().isEmpty) {
      return null;
    }
    if (!context.mounted) return null;

    final rrn = SignupValidators.digitsOnly(submitted);
    if (!SignupValidators.isRrn13Digits(rrn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tilkoNhisLinkRrnInvalid)),
      );
      return null;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '틸코·건강보험 연동 중입니다. 휴대폰에서 카카오 간편인증 알림을 '
            '완료한 뒤 최대 약 2분 기다려 주세요.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }

    final out = await NhisTilkoHiraFlowSync.runTilkoThenHiraWithMedicationsFallback(
      displayName: user.displayName,
      phoneDigits: user.phoneDigits,
      gender: user.gender,
      residentRegistrationDigits13: rrn,
      codefConnectedId: user.codefConnectedId,
    );
    if (!context.mounted || out == null) return null;

    if (announceSuccess &&
        out.result == NhisMedicinesSyncResult.success &&
        !out.showBannerOnBootstrap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeHiraMedicationsLoadSuccess)),
      );
    } else if (out.result == NhisMedicinesSyncResult.failed ||
        out.showBannerOnBootstrap) {
      final msg = out.userMessageKo.trim();
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 8),
          ),
        );
        await HomeNotificationRepository.insertSystemSyncNotice(
          title: l10n.homeNotificationSystemSyncTitle,
          preview: msg,
        );
      }
    }
    return out;
  }

  static Future<void> afterMonthlyEasyAuth() async {
    debugPrint('HIRA: monthly easy-auth token refresh (stub)');
  }
}

/// [TextEditingController] 를 다이얼로그가 소유해, pop 직후 dispose 레이스를 피합니다.
class TilkoNhisRrnDialog extends StatefulWidget {
  const TilkoNhisRrnDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<TilkoNhisRrnDialog> createState() => _TilkoNhisRrnDialogState();
}

class _TilkoNhisRrnDialogState extends State<TilkoNhisRrnDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.tilkoNhisLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tilkoNhisLinkBody,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 13,
            decoration: InputDecoration(
              labelText: l10n.tilkoNhisLinkRrnLabel,
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tilkoNhisLinkSkip),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.tilkoNhisLinkConfirm),
        ),
      ],
    );
  }
}
