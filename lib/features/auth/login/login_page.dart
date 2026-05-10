import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/services/hira_link_service.dart';
import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              DecodedAssetImage(
                ImageAssets.login,
                height: 160,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authWelcomeSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: l10n.socialLoginGoogle,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _socialStub(context),
                    icon: Icon(Icons.g_mobiledata, size: 28, color: scheme.onSurface),
                    label: Text(l10n.socialLoginGoogle),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: l10n.socialLoginApple,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _socialStub(context),
                    icon: Icon(Icons.apple, size: 22, color: scheme.onSurface),
                    label: Text(l10n.socialLoginApple),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.loginDividerEmail,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.loginEmailLabel,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.loginPasswordLabel,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _submit(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.continueCta),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
