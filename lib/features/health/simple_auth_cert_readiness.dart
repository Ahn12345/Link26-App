import 'package:flutter/material.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/integrations/tilko/tilko_env.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// 틸코 NHIS/HIRA 간편인증 전 — 채널(PASS 등) 본인정보 일치 확인.
abstract final class SimpleAuthCertReadiness {
  static final Uri passInfoUri = Uri.parse(
    'https://www.sktpass.com',
  );

  static String formatBirthYmd(String? ymd) {
    final d = (ymd ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return d.isEmpty ? '-' : d;
    return '${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6)}';
  }

  static Future<void> openPassInfo() async {
    await launchUrl(passInfoUri, mode: LaunchMode.externalApplication);
  }

  /// 통신사 PASS 앱 실행. 미설치 시 통신사별 Play 스토어(정식 패키지명)로 안내.
  static Future<void> openPassApp() async {
    const storePackages = <String>[
      'com.sktelecom.tauth', // SKT PASS
      'com.kt.ktauth', // KT PASS
      'com.lguplus.smartotp', // LG U+ PASS
    ];

    final appSchemes = <Uri>[
      Uri.parse('sktpass://'),
      Uri.parse('ktpass://'),
      Uri.parse('upluspass://'),
      Uri.parse('pass://'),
    ];

    for (final uri in appSchemes) {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      }
    }

    for (final pkg in storePackages) {
      final market = Uri.parse('market://details?id=$pkg');
      if (await canLaunchUrl(market)) {
        final ok = await launchUrl(
          market,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      }
      final web = Uri.parse(
        'https://play.google.com/store/apps/details?id=$pkg',
      );
      if (await canLaunchUrl(web)) {
        final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    }

    await openPassInfo();
  }

  /// true = 사용자가 간편인증 본인정보 일치를 확인하고 계속함.
  static Future<bool> confirmBeforeTilkoSync({
    required BuildContext context,
    required String displayName,
    required String phoneDigits,
    String? birthDateYmd,
  }) async {
    final l10n = AppLocalizations.of(context);
    final channel = tilkoPrivateAuthTypeName(TilkoEnv.privateAuthType);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SimpleAuthCertReadinessDialog(
        l10n: l10n,
        channel: channel,
        displayName: displayName.trim(),
        phoneDisplay: UserLocalRepository.formatPhoneDigitsForDisplay(
          phoneDigits.replaceAll(RegExp(r'\D'), ''),
        ),
        birthDisplay: formatBirthYmd(birthDateYmd),
      ),
    );
    return result == true;
  }
}

class _SimpleAuthCertReadinessDialog extends StatefulWidget {
  const _SimpleAuthCertReadinessDialog({
    required this.l10n,
    required this.channel,
    required this.displayName,
    required this.phoneDisplay,
    required this.birthDisplay,
  });

  final AppLocalizations l10n;
  final String channel;
  final String displayName;
  final String phoneDisplay;
  final String birthDisplay;

  @override
  State<_SimpleAuthCertReadinessDialog> createState() =>
      _SimpleAuthCertReadinessDialogState();
}

class _SimpleAuthCertReadinessDialogState
    extends State<_SimpleAuthCertReadinessDialog> {
  var _ack = false;

  bool get _isPass => widget.channel == 'PASS';

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(_isPass ? l10n.passCertDialogTitle : l10n.kakaoCertDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isPass ? l10n.passCertDialogBody : l10n.kakaoCertDialogBody,
              style: TextStyle(
                color: Link26Surface.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            _row(l10n.signupNameLabel, widget.displayName),
            _row(l10n.signupPhoneLabel, widget.phoneDisplay),
            _row(l10n.signupBirthLabel, widget.birthDisplay),
            const SizedBox(height: 12),
            Text(
              _isPass ? l10n.passCertDialogDbNote : l10n.kakaoCertDialogDbNote,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Link26Surface.accent,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isPass
                  ? l10n.passCertAccountSteps
                  : l10n.kakaoCertAccountSteps,
              style: TextStyle(
                fontSize: 13,
                color: Link26Surface.textSecondary,
                height: 1.5,
              ),
            ),
            if (_isPass) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => SimpleAuthCertReadiness.openPassInfo(),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.passCertOpenInfo),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Link26Surface.accent,
                  side: const BorderSide(color: Link26Surface.accent),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await launchUrl(
                    Uri.parse(
                      'https://accounts.kakao.com/weblogin/account/info',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.kakaoCertOpenAccount),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Link26Surface.accent,
                  side: const BorderSide(color: Link26Surface.accent),
                ),
              ),
            ],
            CheckboxListTile(
              value: _ack,
              onChanged: (v) => setState(() => _ack = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                _isPass
                    ? l10n.passCertAcknowledge
                    : l10n.kakaoCertAcknowledge,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: _ack
              ? () async {
                  if (_isPass) {
                    await SimpleAuthCertReadiness.openPassApp();
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Link26Surface.accent,
          ),
          child: Text(
            _isPass ? l10n.passCertContinue : l10n.kakaoCertContinue,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Link26Surface.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
