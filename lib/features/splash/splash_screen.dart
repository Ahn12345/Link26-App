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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 880),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.65, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.88, end: 1).animate(
    CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _intro.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.45),
              scheme.surface,
              scheme.secondaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBrandLogo(width: 160),
                  const SizedBox(height: 28),
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
          ),
        ),
      ),
    );
  }
}
