import 'package:flutter/material.dart';

import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_brand_backdrop.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/widgets/link26_standard_frame.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 인증·연동 실패 등 공용 안내(라우트 연결 시 사용).
class AuthErrorDialog extends StatelessWidget {
  const AuthErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Link26Surface.textPrimary,
        title: Text(
          l10n.authErrorTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Link26BrandBackdrop(
        solidBackground: Link26UnifiedPage.background,
        child: SafeArea(
          child: Link26StandardFrame(
            child: SingleChildScrollView(
              child: Link26FramedPageCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authErrorBody,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: Link26Surface.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: Link26UnifiedPage.filledCtaButton(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(
                        l10n.authErrorBack,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
