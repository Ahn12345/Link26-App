import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../../core/services/auth_session.dart';
import '../../shell/main_shell.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  static const routeName = '/auth/signup';

  static const _illustrationAsset = 'assets/images/signup.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _illustrationAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('signup art: $error');
                    return Icon(
                      Icons.person_add_alt_1,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.signup,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await AuthSession.signIn();
                  if (context.mounted) {
                    await Navigator.of(context).pushNamedAndRemoveUntil(
                      MainShell.routeName,
                      (route) => false,
                    );
                  }
                },
                child: Text(l10n.continueCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
