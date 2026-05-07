import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = '/auth/login';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('LoginPage')),
    );
  }
}