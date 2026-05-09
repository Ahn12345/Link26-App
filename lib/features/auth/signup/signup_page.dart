import 'package:flutter/material.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  static const routeName = '/auth/signup';

  static const _illustrationAsset = 'assets/images/signup.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
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
                    debugPrint('signup art: $error');
                    return Icon(
                      Icons.person_add_alt_1,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SignupPage',
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