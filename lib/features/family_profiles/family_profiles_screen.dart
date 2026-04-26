import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import '../../core/services/family_profile_store.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  static const routeName = '/family-profiles';

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  final _store = FamilyProfileStore();
  List<FamilyProfile> _profiles = const [];
  String? _activeId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _store.loadProfiles();
    var active = await _store.activeProfileId();
    if (active == null && list.isNotEmpty) {
      active = list.first.id;
      await _store.setActiveProfileId(active);
    }
    if (!mounted) return;
    setState(() {
      _profiles = list;
      _activeId = active;
      _loading = false;
    });
  }

  Future<void> _addProfile() async {
    final next = FamilyProfile(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Member ${_profiles.length + 1}',
      avatarEmoji: '⭐',
    );
    await _store.saveProfiles([..._profiles, next]);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familyProfilesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final active = _activeId ?? (_profiles.isNotEmpty ? _profiles.first.id : null);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyProfilesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.familyProfilesSubtitle),
          const SizedBox(height: 8),
          Text(
            l10n.familyProfilesStub,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.activeProfile}: ${active ?? '—'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ..._profiles.map(
            (p) {
              final selected = active == p.id;
              return ListTile(
                leading: Text(
                  p.avatarEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(p.displayName),
                trailing: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () async {
                  await _store.setActiveProfileId(p.id);
                  if (mounted) setState(() => _activeId = p.id);
                },
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addProfile,
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addProfile),
          ),
        ],
      ),
    );
  }
}
