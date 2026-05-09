import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../../core/services/auth_session.dart';
import '../../shell/main_shell.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = '/auth/login';

  static const _illustrationAsset = 'assets/images/simplelogin1.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
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
                    debugPrint('login art: $error');
                    return Icon(
                      Icons.login,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.login,
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
