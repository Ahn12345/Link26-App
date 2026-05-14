import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/core/services/nhis_tilko_codef_flow_sync.dart';
import 'package:link26_app/features/auth/signup/signup_validators.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 가입·로그인 후 틸코 간편인증 → BFF 심평원 복약(hiraa050300000100) 조회.
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
    final out = await NhisTilkoCodefFlowSync.runTilkoThenNhisWithMedicationsFallback(
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

  /// 로그인 직후 — 주민번호는 기기에 저장하지 않으므로, 건보 조회 시 한 번 입력받습니다.
  static Future<void> afterLogin({
    required BuildContext context,
    required LocalUserRecord user,
  }) async {
    if (!context.mounted) return;
    try {
      await dotenv.load(fileName: 'assets/env/dotenv');
    } catch (_) {}

    if (!context.mounted) return;

    if (NhisRuntimeConfig.useMock || !Link26BffIntegrationsClient.canCall) {
      if (kDebugMode) {
        debugPrint(
          'HIRA: 틸코→건보 플로우 생략 (mock 또는 NHIS_BASE_URL 없음)',
        );
      }
      return;
    }

    final l10n = AppLocalizations.of(context);
    final submitted = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _TilkoNhisRrnDialog(l10n: l10n),
    );

    if (submitted == null || submitted.trim().isEmpty) {
      return;
    }
    if (!context.mounted) return;

    final rrn = SignupValidators.digitsOnly(submitted);
    if (!SignupValidators.isRrn13Digits(rrn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tilkoNhisLinkRrnInvalid)),
      );
      return;
    }

    final out = await NhisTilkoCodefFlowSync.runTilkoThenNhisWithMedicationsFallback(
      displayName: user.displayName,
      phoneDigits: user.phoneDigits,
      gender: user.gender,
      residentRegistrationDigits13: rrn,
      codefConnectedId: user.codefConnectedId,
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

  static Future<void> afterMonthlyEasyAuth() async {
    debugPrint('HIRA: monthly easy-auth token refresh (stub)');
  }
}

/// [TextEditingController] 를 다이얼로그가 소유해, pop 직후 dispose 레이스를 피합니다.
class _TilkoNhisRrnDialog extends StatefulWidget {
  const _TilkoNhisRrnDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_TilkoNhisRrnDialog> createState() => _TilkoNhisRrnDialogState();
}

class _TilkoNhisRrnDialogState extends State<_TilkoNhisRrnDialog> {
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
