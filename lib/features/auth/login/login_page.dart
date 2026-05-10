import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/hira_link_service.dart';
import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';
import 'package:link26_app/features/shell/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/auth/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRegisteredUser());
  }

  Future<void> _ensureRegisteredUser() async {
    final has = await UserLocalRepository.hasAnyUser();
    if (!mounted) return;
    if (!has) {
      await Navigator.of(context).pushReplacementNamed(SignupPage.routeName);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
    final ok = await UserLocalRepository.verifyCredentials(email, password);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginFailed)),
      );
      return;
    }
    await AuthSession.signIn();
    await HiraLinkService.afterLogin();
    if (context.mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        MainShell.routeName,
        (route) => false,
      );
    }
  }

  void _socialStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).socialLoginComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outlineBtn = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: Link26Surface.textPrimary,
      side: const BorderSide(color: Link26Surface.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Link26Surface.radiusButton),
      ),
    );
    final w = MediaQuery.sizeOf(context).width;
    final heroH = Link26ResponsiveImageHeights.login(w);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: SafeArea(
        child: Link26ResponsiveScroll(
          child: LayoutBuilder(
            builder: (context, c) {
              final contentW = c.maxWidth;
              final heroW = Link26ResponsiveImageHeights.loginDisplayWidth(w).clamp(0.0, contentW);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Link26ElevatedCard(
                    padding: EdgeInsets.all(Link26ResponsiveUi.profileCardPadding(w)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SizedBox(
                            width: heroW,
                            child: DecodedAssetImage(
                              ImageAssets.login,
                              height: heroH,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(Link26Surface.radiusInput),
                            ),
                          ),
                        ),
                    SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                    Text(
                      l10n.authWelcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Link26Surface.textSecondary,
                        fontSize: Link26ResponsiveUi.body(w),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Link26ResponsiveUi.gapXl(w)),
              Semantics(
                button: true,
                label: l10n.socialLoginGoogle,
                child: OutlinedButton.icon(
                  style: outlineBtn,
                  onPressed: () => _socialStub(context),
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Link26Surface.textPrimary),
                  label: Text(l10n.socialLoginGoogle),
                ),
              ),
              SizedBox(height: Link26ResponsiveUi.gapSm(w)),
              Semantics(
                button: true,
                label: l10n.socialLoginApple,
                child: OutlinedButton.icon(
                  style: outlineBtn,
                  onPressed: () => _socialStub(context),
                  icon: const Icon(Icons.apple, size: 22, color: Link26Surface.textPrimary),
                  label: Text(l10n.socialLoginApple),
                ),
              ),
              SizedBox(height: Link26ResponsiveUi.chatHeaderTitleGap(w) + Link26ResponsiveUi.gapXs(w)),
              Row(
                children: [
                  const Expanded(child: Divider(color: Link26Surface.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.loginDividerEmail,
                      style: TextStyle(
                        color: Link26Surface.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: Link26ResponsiveUi.bodySmall(w),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Link26Surface.outline)),
                ],
              ),
              SizedBox(height: Link26ResponsiveUi.gapXl(w)),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Link26Surface.textPrimary,
                  fontSize: Link26ResponsiveUi.body(w),
                ),
                decoration: Link26Surface.inputDecoration(labelText: l10n.loginEmailLabel),
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
                decoration: Link26Surface.inputDecoration(labelText: l10n.loginPasswordLabel),
              ),
              SizedBox(height: Link26ResponsiveUi.authCardPadVertical(w)),
              FilledButton(
                onPressed: () => _submit(context),
                style: Link26Surface.filledAccentButton(minimumSize: const Size.fromHeight(52)),
                child: Text(l10n.continueCta, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              SizedBox(height: Link26ResponsiveUi.gapLg(w)),
            ],
              );
            },
          ),
        ),
      ),
    );
  }
}
