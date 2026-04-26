import 'package:flutter/material.dart';

/// 회원가입 화면 UI
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  static const routeName = '/auth/signup';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('SignupPage')),
    );
  }
}
