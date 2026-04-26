import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import '../../core/services/family_voice_service.dart';

class FamilyVoiceScreen extends StatefulWidget {
  const FamilyVoiceScreen({super.key});

  static const routeName = '/family-voice';

  @override
  State<FamilyVoiceScreen> createState() => _FamilyVoiceScreenState();
}

class _FamilyVoiceScreenState extends State<FamilyVoiceScreen> {
  final _service = FamilyVoiceService();
  late Future<List<FamilyVoiceClip>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listClips();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyVoiceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.familyVoiceSubtitle),
          const SizedBox(height: 8),
          Text(
            l10n.familyVoiceStub,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.familyVoiceStub)),
              );
            },
            icon: const Icon(Icons.mic),
            label: Text(l10n.recordVoiceImport),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<FamilyVoiceClip>>(
            future: _future,
            builder: (context, snapshot) {
              final clips = snapshot.data ?? const <FamilyVoiceClip>[];
              if (clips.isEmpty) {
                return Text(
                  'No clips yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: clips
                    .map(
                      (c) => ListTile(
                        leading: const Icon(Icons.graphic_eq),
                        title: Text(c.label),
                        subtitle: Text(c.relativePath),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
