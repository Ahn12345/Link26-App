import 'package:flutter/material.dart';

class AuthErrorDialog extends StatelessWidget {
  const AuthErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth_error_dialog')),
      body: const Center(child: Text('TODO UI')),
    );
  }
}
