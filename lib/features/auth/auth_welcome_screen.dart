import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/features/auth/login/login_page.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';

/// 스플래시 이후 — 브랜드 [ImageAssets.logo] + 로그인 / 회원가입.
class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  static const routeName = '/auth/welcome';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Image.asset(
                  ImageAssets.logo,
                  height: 120,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.authWelcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(LoginPage.routeName);
                  },
                  child: Text(l10n.login),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(SignupPage.routeName),
                  child: Text(l10n.signup),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
