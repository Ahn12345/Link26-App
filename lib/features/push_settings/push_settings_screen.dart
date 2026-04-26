import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import '../../core/services/push_notification_service.dart';

class PushSettingsScreen extends StatefulWidget {
  const PushSettingsScreen({super.key});

  static const routeName = '/push-settings';

  @override
  State<PushSettingsScreen> createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {
  final _service = PushNotificationService();
  bool _medicine = true;
  bool _family = true;
  bool _system = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pushSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.pushSettingsSubtitle),
          const SizedBox(height: 8),
          Text(l10n.pushStub, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Medicine reminders'),
            value: _medicine,
            onChanged: (v) => setState(() => _medicine = v),
          ),
          SwitchListTile(
            title: const Text('Family / household'),
            value: _family,
            onChanged: (v) => setState(() => _family = v),
          ),
          SwitchListTile(
            title: const Text('System announcements'),
            value: _system,
            onChanged: (v) => setState(() => _system = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await _service.initialize();
              await _service.requestPermission();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pushStub)),
                );
              }
            },
            child: const Text('Register for push (stub)'),
          ),
        ],
      ),
    );
  }
}
