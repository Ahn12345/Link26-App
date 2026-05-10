import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';

/// 네이티브 스플래시와 맞춘 배경색 + [ImageAssets.applogo] (런처 아이콘과 동일 에셋).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

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
    await Future<void>.delayed(const Duration(milliseconds: 500));
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
            Image.asset(
              ImageAssets.applogo,
              width: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: primary),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
