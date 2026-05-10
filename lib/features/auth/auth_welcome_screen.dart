import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/constants/build_identity.dart';
import 'package:link26_app/core/widgets/app_brand_logo.dart';
import 'package:link26_app/features/auth/login/login_page.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';

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
              const SizedBox(height: 24),
              const AppBrandLogo(height: 100),
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
              Text(
                BuildIdentity.marker,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                BuildIdentity.openFrom,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
