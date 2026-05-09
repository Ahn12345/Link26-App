import 'package:flutter/material.dart';

import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/widgets/app_brand_logo.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';
import 'package:link26_app/features/shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final signedIn = await AuthSession.isSignedIn();
    if (!mounted) return;
    if (signedIn) {
      await Navigator.of(context).pushReplacementNamed(MainShell.routeName);
    } else {
      await Navigator.of(context)
          .pushReplacementNamed(AuthWelcomeScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppBrandLogo(width: 160),
            const SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
