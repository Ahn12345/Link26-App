import 'package:flutter/material.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// 틸코 NHIS 간편인증 전 — 카카오 본인인증(실명·휴대폰·생년월일) 일치 확인.
abstract final class KakaoCertReadiness {
  static final Uri kakaoAccountUri = Uri.parse(
    'https://accounts.kakao.com/weblogin/account/info',
  );

  static String formatBirthYmd(String? ymd) {
    final d = (ymd ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return d.isEmpty ? '-' : d;
    return '${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6)}';
  }

  static Future<void> openKakaoAccountSettings() async {
    await launchUrl(kakaoAccountUri, mode: LaunchMode.externalApplication);
  }

  /// true = 사용자가 카카오 본인정보 일치를 확인하고 계속함.
  static Future<bool> confirmBeforeTilkoSync({
    required BuildContext context,
    required String displayName,
    required String phoneDigits,
    String? birthDateYmd,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KakaoCertReadinessDialog(
        l10n: l10n,
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

class _KakaoCertReadinessDialog extends StatefulWidget {
  const _KakaoCertReadinessDialog({
    required this.l10n,
    required this.displayName,
    required this.phoneDisplay,
    required this.birthDisplay,
  });

  final AppLocalizations l10n;
  final String displayName;
  final String phoneDisplay;
  final String birthDisplay;

  @override
  State<_KakaoCertReadinessDialog> createState() =>
      _KakaoCertReadinessDialogState();
}

class _KakaoCertReadinessDialogState extends State<_KakaoCertReadinessDialog> {
  var _ack = false;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.kakaoCertDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.kakaoCertDialogBody,
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
              l10n.kakaoCertDialogDbNote,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Link26Surface.accent,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => KakaoCertReadiness.openKakaoAccountSettings(),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.kakaoCertOpenAccount),
              style: OutlinedButton.styleFrom(
                foregroundColor: Link26Surface.accent,
                side: const BorderSide(color: Link26Surface.accent),
              ),
            ),
            CheckboxListTile(
              value: _ack,
              onChanged: (v) => setState(() => _ack = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                l10n.kakaoCertAcknowledge,
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
          onPressed: _ack ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Link26Surface.accent,
          ),
          child: Text(l10n.kakaoCertContinue),
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
