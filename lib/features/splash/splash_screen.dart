import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/build_identity.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';

/// 네이티브 스플래시(`link26_splash_screen.xml`)와 동일 배경색만 유지해 깜빡임을 줄입니다.
/// 이후 항상 [AuthWelcomeScreen] 으로 이동합니다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  /// `colors.xml` 의 `splash_background` / `link26_scaffold_tint` 와 동일.
  static const Color splashColor = Color(0xFFEEF4FA);

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
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).pushReplacementNamed(AuthWelcomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: SplashScreen.splashColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: primary),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                BuildIdentity.marker,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
