import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/features/auth/login/login_page.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';

/// 스플래시 이후 — 브랜드 + 로그인 / 회원가입.
class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  static const routeName = '/auth/welcome';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outlineBtn = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: Link26Surface.accent,
      side: const BorderSide(color: Link26Surface.accent, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Link26Surface.radiusButton),
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Link26Surface.backdropGradient,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final pad = Link26Layout.pageInsets(w);
              final logoH = Link26ResponsiveImageHeights.authWelcome(w);
              final logoW = Link26ResponsiveImageHeights.authWelcomeDisplayWidth(w);
              return Padding(
                padding: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Link26ResponsiveTokens.contentMaxWidth,
                        ),
                        child: Link26ElevatedCard(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          child: Column(
                            children: [
                              Center(
                                child: SizedBox(
                                  width: logoW,
                                  child: DecodedAssetImage(
                                    ImageAssets.logo,
                                    height: logoH,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.appTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Link26Surface.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.authWelcomeSubtitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Link26Surface.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Link26ResponsiveTokens.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(LoginPage.routeName);
                              },
                              style: Link26Surface.filledAccentButton(
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: Text(l10n.login, style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed(SignupPage.routeName),
                              style: outlineBtn,
                              child: Text(l10n.signup, style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
