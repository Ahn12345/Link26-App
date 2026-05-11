import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/hira_link_service.dart';
import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_brand_backdrop.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/widgets/link26_standard_frame.dart';
import 'package:link26_app/features/auth/services/nhis_login_sync.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';
import 'package:sqflite/sqflite.dart';

import 'package:link26_app/features/auth/signup/signup_validators.dart';
import 'package:link26_app/features/shell/main_shell.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/auth/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRegisteredUser());
  }

  Future<void> _ensureRegisteredUser() async {
    try {
      final has = await UserLocalRepository.hasAnyUser();
      if (!mounted) return;
      if (!has) {
        await Navigator.of(context).pushReplacementNamed(SignupPage.routeName);
      }
    } catch (e, st) {
      debugPrint('LoginPage: ensureRegisteredUser failed: $e\n$st');
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.authSessionInitFailed)),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginNameRequired)),
      );
      return;
    }
    if (SignupValidators.digitsOnly(phone).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginPhoneRequired)),
      );
      return;
    }
    if (!SignupValidators.isPhoneKr(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupPhoneInvalid)),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final phoneDigits = SignupValidators.digitsOnly(phone);
      final byPhone =
          await UserLocalRepository.findUserByPhone(phoneDigits);
      if (!context.mounted) return;

      if (byPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginRedirectToSignup)),
        );
        await Navigator.of(context).pushReplacementNamed(SignupPage.routeName);
        return;
      }

      final nameNorm = UserLocalRepository.normalizeDisplayName(name);
      if (byPhone.displayName != nameNorm) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginNameMismatch)),
        );
        return;
      }

      final user = byPhone;

      final nhisOutcome =
          await NhisLoginSync.syncAfterLocalLogin(user: user);
      if (!context.mounted) return;

      if (nhisOutcome.result == NhisLoginSyncResult.failed) {
        if (NhisRuntimeConfig.loginRequired) {
          final detail = nhisOutcome.detailKo;
          final body = detail != null && detail.isNotEmpty
              ? '${l10n.loginNhisRequiredFailed}\n\n$detail'
              : l10n.loginNhisRequiredFailed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body)),
          );
          return;
        }
        final detail = nhisOutcome.detailKo;
        final body = detail != null && detail.isNotEmpty
            ? '${l10n.loginNhisSyncFailed}\n\n$detail'
            : l10n.loginNhisSyncFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body),
            duration: const Duration(seconds: 8),
          ),
        );
      }

      await AuthSession.signIn(phoneDigits: user.phoneDigits);
      await HiraLinkService.afterLogin();
      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          MainShell.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final body = e is DatabaseException
            ? l10n.authSessionInitFailed
            : '${l10n.loginFailed}: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _socialStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context).socialLoginComingSoon)),
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
    final nameOk = _nameCtrl.text.trim().isNotEmpty;
    final phoneOk = SignupValidators.isPhoneKr(_phoneCtrl.text);
    final canLocalLogin = nameOk && phoneOk;

    final topUnderAppBar =
        MediaQuery.viewPaddingOf(context).top + kToolbarHeight;
    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Link26Surface.textPrimary,
        title: Text(
          l10n.login,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Link26BrandBackdrop(
        solidBackground: Link26UnifiedPage.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: topUnderAppBar),
            child: Link26StandardFrame(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, c) {
                  final contentW = c.maxWidth;
                  final heroW = Link26ResponsiveImageHeights.loginDisplayWidth(w)
                      .clamp(0.0, contentW);
                  return Link26FramedPageCard(
                    padding: EdgeInsets.symmetric(
                      vertical: Link26ResponsiveUi.authCardPadVertical(w),
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
                              ImageAssets.login,
                              height: heroH,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(
                                Link26Surface.radiusInput,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: Link26ResponsiveUi.heroArtToContent(w)),
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
                        SizedBox(height: Link26ResponsiveUi.gapXl(w)),
                        Semantics(
                          button: true,
                          label: l10n.socialLoginGoogle,
                          child: OutlinedButton.icon(
                            style: outlineBtn,
                            onPressed: () => _socialStub(context),
                            icon: const Icon(Icons.g_mobiledata,
                                size: 28, color: Link26Surface.textPrimary),
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
                            icon: const Icon(Icons.apple,
                                size: 22, color: Link26Surface.textPrimary),
                            label: Text(l10n.socialLoginApple),
                          ),
                        ),
                        SizedBox(
                          height: Link26ResponsiveUi.chatHeaderTitleGap(w) +
                              Link26ResponsiveUi.gapXs(w),
                        ),
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Link26Surface.outline)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                l10n.loginDividerLocalAccount,
                                style: TextStyle(
                                  color: Link26Surface.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: Link26ResponsiveUi.bodySmall(w),
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Link26Surface.outline)),
                          ],
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapXl(w)),
                        TextField(
                          controller: _nameCtrl,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Link26Surface.textPrimary,
                            fontSize: Link26ResponsiveUi.body(w),
                          ),
                          decoration: Link26Surface.inputDecoration(
                            labelText: l10n.loginNameLabel,
                          ),
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                        TextField(
                          controller: _phoneCtrl,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Link26Surface.textPrimary,
                            fontSize: Link26ResponsiveUi.body(w),
                          ),
                          decoration: Link26Surface.inputDecoration(
                            labelText: l10n.signupPhoneLabel,
                          ),
                        ),
                        SizedBox(
                          height: Link26ResponsiveUi.authCardPadVertical(w),
                        ),
                        FilledButton(
                          onPressed: (_busy || !canLocalLogin)
                              ? null
                              : () => _submit(context),
                          style: Link26UnifiedPage.filledCtaButton(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.continueCta,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                        ),
                        if (!_busy && !canLocalLogin) ...[
                          SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                          Text(
                            l10n.authContinueLoginHint,
                            style: TextStyle(
                              fontSize: Link26ResponsiveUi.bodySmall(w),
                              color: Link26Surface.textMuted,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
