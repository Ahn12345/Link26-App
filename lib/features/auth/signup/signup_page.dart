import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_brand_backdrop.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/hira_link_service.dart';
import 'package:link26_app/features/auth/services/nhis_signup_sync.dart';
import 'package:link26_app/features/auth/signup/signup_validators.dart';
import 'package:link26_app/features/shell/main_shell.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static const routeName = '/auth/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rrnCtrl = TextEditingController();

  /// `male` | `female`
  String? _gender;
  bool _privacyAgreed = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _rrnCtrl.dispose();
    super.dispose();
  }

  bool _allRequiredFilled(AppLocalizations l10n) {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (!SignupValidators.isPhoneKr(_phoneCtrl.text)) return false;
    if (_gender == null) return false;
    if (!SignupValidators.isRrn13Digits(_rrnCtrl.text)) return false;
    if (!_privacyAgreed) return false;
    return true;
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupNameRequired)),
      );
      return;
    }
    if (!SignupValidators.isPhoneKr(_phoneCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupPhoneInvalid)),
      );
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupGenderRequired)),
      );
      return;
    }
    if (!SignupValidators.isRrn13Digits(_rrnCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupRrnInvalid)),
      );
      return;
    }
    if (!_privacyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupPrivacyRequired)),
      );
      return;
    }

    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (await UserLocalRepository.phoneExists(_phoneCtrl.text)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signupPhoneTaken)),
        );
        return;
      }
      try {
        await UserLocalRepository.register(
          displayName: _nameCtrl.text.trim(),
          phone: SignupValidators.digitsOnly(_phoneCtrl.text),
          gender: _gender!,
          residentRegistrationDigits13:
              SignupValidators.digitsOnly(_rrnCtrl.text),
          privacyConsent: true,
        );
      } on DatabaseException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signupPhoneTaken)),
        );
        return;
      }

      final phoneDigits = SignupValidators.digitsOnly(_phoneCtrl.text);
      final rrnDigits = SignupValidators.digitsOnly(_rrnCtrl.text);
      final rrnHash =
          UserLocalRepository.residentRegistrationSha256(rrnDigits);

      final nhisResult = await NhisSignupSync.syncAfterLocalRegister(
        displayName: _nameCtrl.text.trim(),
        phoneDigits: phoneDigits,
        gender: _gender!,
        residentRegistrationHash: rrnHash,
      );

      if (!context.mounted) return;

      if (nhisResult == NhisSignupSyncResult.failed) {
        if (NhisRuntimeConfig.signupRequired) {
          await UserLocalRepository.deleteUserByPhone(phoneDigits);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signupNhisRequiredFailed)),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signupNhisSyncFailed)),
        );
      }

      await HiraLinkService.afterRegistration();
      await AuthSession.signIn();
      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          MainShell.routeName,
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final heroH = Link26ResponsiveImageHeights.signup(w);
    final topUnderAppBar =
        MediaQuery.viewPaddingOf(context).top + kToolbarHeight;
    final canSubmit = _allRequiredFilled(l10n) && !_busy;

    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Link26Surface.textPrimary,
        title: Text(
          l10n.signup,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Link26BrandBackdrop(
        solidBackground: Link26UnifiedPage.background,
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
                        SizedBox(
                            height: Link26ResponsiveUi.heroArtToContent(w)),
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
                            labelText: l10n.signupNameLabel,
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
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Link26Surface.textPrimary,
                            fontSize: Link26ResponsiveUi.body(w),
                          ),
                          decoration: Link26Surface.inputDecoration(
                            labelText: l10n.signupPhoneLabel,
                          ),
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                        Text(
                          l10n.signupGenderLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: Link26ResponsiveUi.bodySmall(w),
                            color: Link26Surface.textSecondary,
                          ),
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _gender = 'male'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Link26Surface.textPrimary,
                                  backgroundColor: _gender == 'male'
                                      ? Link26Surface.chipTint
                                      : null,
                                  side: BorderSide(
                                    color: _gender == 'male'
                                        ? Link26Surface.accent
                                        : Link26Surface.outline,
                                    width: _gender == 'male' ? 2 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Link26Surface.radiusButton,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  l10n.signupGenderMale,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            SizedBox(width: Link26ResponsiveUi.gapMd(w)),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _gender = 'female'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Link26Surface.textPrimary,
                                  backgroundColor: _gender == 'female'
                                      ? Link26Surface.chipTint
                                      : null,
                                  side: BorderSide(
                                    color: _gender == 'female'
                                        ? Link26Surface.accent
                                        : Link26Surface.outline,
                                    width: _gender == 'female' ? 2 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Link26Surface.radiusButton,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  l10n.signupGenderFemale,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                        TextField(
                          controller: _rrnCtrl,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(13),
                          ],
                          textInputAction: TextInputAction.done,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Link26Surface.textPrimary,
                            fontSize: Link26ResponsiveUi.body(w),
                          ),
                          decoration: Link26Surface.inputDecoration(
                            labelText: l10n.signupRrnLabel,
                          ).copyWith(
                            hintText: l10n.signupRrnHint,
                            hintStyle: TextStyle(
                              color: Link26Surface.textMuted,
                              fontSize: Link26ResponsiveUi.bodySmall(w),
                            ),
                          ),
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                        CheckboxListTile(
                          value: _privacyAgreed,
                          onChanged: (v) =>
                              setState(() => _privacyAgreed = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            l10n.signupPrivacyAgree,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: Link26ResponsiveUi.bodySmall(w),
                              color: Link26Surface.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          activeColor: Link26Surface.accent,
                        ),
                        SizedBox(
                          height: Link26ResponsiveUi.authCardPadVertical(w),
                        ),
                        FilledButton(
                          onPressed:
                              canSubmit ? () => _submit(context) : null,
                          style: Link26UnifiedPage.filledCtaButton(
                            minimumSize: const Size.fromHeight(52),
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
                      ],
                    ),
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
