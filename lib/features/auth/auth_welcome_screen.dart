import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'login/login_page.dart';
import 'signup/signup_page.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  static const routeName = '/auth/welcome';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.link, size: 80, color: scheme.primary),
              ),
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
                onPressed: () =>
                    Navigator.of(context).pushNamed(LoginPage.routeName),
                child: Text(l10n.login),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(SignupPage.routeName),
                child: Text(l10n.signup),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
