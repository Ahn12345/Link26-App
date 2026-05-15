import 'package:flutter/material.dart';

import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';
import 'package:link26_app/features/shell/main_shell.dart';

/// 앱 cold start 시 로그인 세션이 있으면 환영 화면을 건너뛰고 [MainShell] 로 갑니다.
class Link26SessionGate extends StatelessWidget {
  const Link26SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthSession.isSignedIn(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Link26UnifiedPage.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == true) {
          return const MainShell();
        }
        return const AuthWelcomeScreen();
      },
    );
  }
}
