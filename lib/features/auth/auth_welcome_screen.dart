import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/design/link26_design_catalog.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_brand_backdrop.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/widgets/link26_standard_frame.dart';
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
      minimumSize: const Size.fromHeight(56),
      foregroundColor: Link26UnifiedPage.ctaBlue,
      side: const BorderSide(color: Link26UnifiedPage.ctaBlue, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Link26Surface.radiusButton),
      ),
    );

    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      body: Link26BrandBackdrop(
        solidBackground: Link26UnifiedPage.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final logoH = Link26ResponsiveImageHeights.authWelcome(w);
              final logoW = Link26ResponsiveImageHeights.authWelcomeDisplayWidth(w);
              final authPadV = Link26ResponsiveUi.authCardPadVertical(w);
              final authPadH = Link26ResponsiveUi.authCardPadHorizontal(w);
              final welcomeTop = Link26ResponsiveUi.welcomeTopInset(w);
              return Link26StandardFrame(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: welcomeTop),
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Link26Layout.innerWidth(w),
                          ),
                          child: Link26FramedPageCard(
                            padding: EdgeInsets.symmetric(vertical: authPadV, horizontal: authPadH),
                            child: Column(
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: logoW,
                                    height: logoH,
                                    child: DecodedAssetImage(
                                      Link26DesignCatalog.heroAssetPath(
                                          'logo', ImageAssets.logo),
                                      width: logoW,
                                      height: logoH,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
                                Text(
                                  l10n.appTitle,
                                  style: TextStyle(
                                    fontSize: Link26ResponsiveUi.appMarketingTitle(w),
                                    fontWeight: FontWeight.w900,
                                    color: Link26Surface.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                                Text(
                                  l10n.authWelcomeSubtitle,
                                  style: TextStyle(
                                    fontSize: Link26ResponsiveUi.appMarketingSubtitle(w),
                                    color: Link26Surface.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height: Link26ResponsiveUi.gapLg(w) +
                                      Link26ResponsiveUi.gapMd(w) +
                                      Link26ResponsiveUi.gapMd(w) +
                                      32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: (c.maxHeight * 0.03).clamp(12.0, 40.0),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Link26Layout.innerWidth(w),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(LoginPage.routeName);
                                },
                                style: Link26UnifiedPage.filledCtaButton(
                                  minimumSize: const Size.fromHeight(56),
                                ),
                                child: Text(l10n.login, style: const TextStyle(fontWeight: FontWeight.w800)),
                              ),
                              SizedBox(height: Link26ResponsiveUi.gapMd(w)),
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
                      SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
