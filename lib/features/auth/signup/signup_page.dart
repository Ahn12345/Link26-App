import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Link26ElevatedCard(
                padding: const EdgeInsets.all(16),
                child: DecodedAssetImage(
                  ImageAssets.signup,
                  height: 160,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 20),
              Text(
                l10n.signup,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Link26Surface.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Link26Surface.textPrimary),
                decoration: Link26Surface.inputDecoration(labelText: l10n.signupNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Link26Surface.textPrimary),
                decoration: Link26Surface.inputDecoration(labelText: l10n.loginEmailLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Link26Surface.textPrimary),
                decoration: Link26Surface.inputDecoration(labelText: l10n.loginPasswordLabel),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _submit(context),
                style: Link26Surface.filledAccentButton(minimumSize: const Size.fromHeight(52)),
                child: Text(l10n.continueCta, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
