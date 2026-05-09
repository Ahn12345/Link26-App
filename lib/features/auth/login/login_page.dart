import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = '/auth/login';

  static const _illustrationAsset = 'assets/images/simplelogin1.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _illustrationAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('login art: $error');
                    return Icon(
                      Icons.login,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LoginPage',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}