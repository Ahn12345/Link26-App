import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 디자인 에셋 `emergencycall.png` — 긴급 연락 UX (실제 전화는 추후 `tel:` 연동).
class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});

  static const routeName = '/emergency-contact';

  static const _asset = 'assets/images/emergencycall.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEmergencyContact)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              _asset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.phone_in_talk, size: 120),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.emergencyContactStub,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.emergencyCallPlaceholder)),
              );
            },
            icon: const Icon(Icons.call),
            label: Text(l10n.emergencyCallAction),
          ),
        ],
      ),
    );
  }
}
