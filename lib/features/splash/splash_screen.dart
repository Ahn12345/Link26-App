import 'package:flutter/material.dart';

import '../../core/services/auth_session.dart';
import '../auth/auth_welcome_screen.dart';
import '../shell/main_shell.dart';

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
            Image.asset(
              'assets/images/logo.png',
              width: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('logo2: $error');
                return Icon(
                  Icons.link,
                  size: 80,
                  color: scheme.primary,
                );
              },
            ),
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
