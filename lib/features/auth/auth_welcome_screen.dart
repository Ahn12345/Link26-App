import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/core/constants/app_build_fingerprint.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_auth_brand_logo.dart';
import 'package:link26_app/core/widgets/link26_brand_backdrop.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/widgets/link26_standard_frame.dart';
import 'package:link26_app/features/auth/login/login_page.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';

class AuthWelcomeScreen extends StatefulWidget {
  const AuthWelcomeScreen({super.key});
  static const routeName = '/auth/welcome';
  @override
  State<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends State<AuthWelcomeScreen> {
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
              final inner = Link26Layout.innerWidth(w);
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
                                Link26AuthBrandLogo(maxWidth: inner),
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
                                if (kDebugMode) ...[
                                  SizedBox(
                                    height: Link26ResponsiveUi.gapLg(w) +
                                        Link26ResponsiveUi.gapMd(w) +
                                        Link26ResponsiveUi.gapMd(w) +
                                        16,
                                  ),
                                  Text(
                                    '빌드 $kAppBuildNumber · $kAppBuildTag\n'
                                    '이 문구가 보이면 이 소스에서 만든 최신 APK입니다.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                      color: Link26Surface.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
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
                                onPressed: () async {
                                  final has =
                                      await UserLocalRepository.hasAnyUser();
                                  if (!context.mounted) return;
                                  if (!has) {
                                    await Navigator.of(context)
                                        .pushNamed(SignupPage.routeName);
                                  } else {
                                    await Navigator.of(context)
                                        .pushNamed(LoginPage.routeName);
                                  }
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