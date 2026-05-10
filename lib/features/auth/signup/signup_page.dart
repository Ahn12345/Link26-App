import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_brand_backdrop.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/hira_link_service.dart';
import 'package:link26_app/features/shell/main_shell.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static const routeName = '/auth/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginFieldsRequired)),
      );
      return;
    }
    if (await UserLocalRepository.emailExists(email)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupEmailTaken)),
      );
      return;
    }
    try {
      await UserLocalRepository.register(
        email: email,
        password: password,
        displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
    } on DatabaseException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupEmailTaken)),
      );
      return;
    }
    await HiraLinkService.afterRegistration();
    await AuthSession.signIn();
    if (context.mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        MainShell.routeName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final heroH = Link26ResponsiveImageHeights.signup(w);
    final topUnderAppBar =
        MediaQuery.viewPaddingOf(context).top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Link26Surface.textPrimary,
        title: Text(l10n.signup),
      ),
      body: Link26BrandBackdrop(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: topUnderAppBar),
            child: Link26ResponsiveScroll(
              child: LayoutBuilder(
                builder: (context, c) {
                  final contentW = c.maxWidth;
                  final heroW = Link26ResponsiveImageHeights.signupDisplayWidth(w)
                      .clamp(0.0, contentW);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Link26ElevatedCard(
                        padding: EdgeInsets.symmetric(
                          vertical:
                              Link26ResponsiveUi.authCardPadVertical(w),
                          horizontal:
                              Link26ResponsiveUi.authCardPadHorizontal(w),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: SizedBox(
                                width: heroW,
                                child: DecodedAssetImage(
                                  ImageAssets.signup,
                                  height: heroH,
                                  fit: BoxFit.contain,
                                  borderRadius: BorderRadius.circular(
                                    Link26Surface.radiusInput,
                                  ),
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('signup art: $error');
                                    return const Icon(
                                      Icons.person_add_alt_1,
                                      size: 120,
                                      color: Link26Surface.accent,
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
                            Text(
                              l10n.signup,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    Link26ResponsiveUi.appMarketingTitle(w),
                                fontWeight: FontWeight.w900,
                                color: Link26Surface.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                            Text(
                              l10n.authWelcomeSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: Link26ResponsiveUi
                                    .appMarketingSubtitle(w),
                                color: Link26Surface.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapXl(w)),
                      TextField(
                        controller: _nameCtrl,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Link26Surface.textPrimary,
                          fontSize: Link26ResponsiveUi.body(w),
                        ),
                        decoration: Link26Surface.inputDecoration(
                          labelText: l10n.signupNameLabel,
                        ),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Link26Surface.textPrimary,
                          fontSize: Link26ResponsiveUi.body(w),
                        ),
                        decoration: Link26Surface.inputDecoration(
                          labelText: l10n.loginEmailLabel,
                        ),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Link26Surface.textPrimary,
                          fontSize: Link26ResponsiveUi.body(w),
                        ),
                        decoration: Link26Surface.inputDecoration(
                          labelText: l10n.loginPasswordLabel,
                        ),
                      ),
                      SizedBox(
                        height: Link26ResponsiveUi.authCardPadVertical(w),
                      ),
                      FilledButton(
                        onPressed: () => _submit(context),
                        style: Link26Surface.filledAccentButton(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(
                          l10n.continueCta,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
