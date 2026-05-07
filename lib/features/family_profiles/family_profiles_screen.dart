import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/services/family_profile_store.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  static const routeName = '/family-profiles';

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  static const int _maxProfiles = 5;

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
    var list = await _store.loadProfiles();
    if (list.length > _maxProfiles) {
      list = list.take(_maxProfiles).toList();
      await _store.saveProfiles(list);
    }
    var active = await _store.activeProfileId();
    if (active != null && list.every((p) => p.id != active)) {
      active = null;
    }
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
    if (_profiles.length >= _maxProfiles) {
      final isKorean = Localizations.localeOf(context).languageCode == 'ko';
      final message = isKorean
          ? '가족 계정은 최대 5명까지 추가할 수 있습니다.'
          : 'You can add up to 5 family profiles.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final next = FamilyProfile(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Member ${_profiles.length + 1}',
      avatarEmoji: '*',
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
            '$_maxProfiles max / ${_profiles.length} added',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.activeProfile}: ${active ?? '-'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ..._profiles.map((p) {
            final selected = active == p.id;
            return ListTile(
              leading: Text(
                p.avatarEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(p.displayName),
              trailing: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () async {
                await _store.setActiveProfileId(p.id);
                if (mounted) setState(() => _activeId = p.id);
              },
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _profiles.length >= _maxProfiles ? null : _addProfile,
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addProfile),
          ),
        ],
      ),
    );
  }
}
