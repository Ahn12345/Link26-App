import 'package:shared_preferences/shared_preferences.dart';

/// Local profile storage. Can be replaced with backend sync later.
class FamilyProfile {
  const FamilyProfile({
    required this.id,
    required this.displayName,
    this.avatarEmoji = 'U',
  });

  final String id;
  final String displayName;
  final String avatarEmoji;
}

class FamilyProfileStore {
  static const _key = 'family_profiles_v1';
  static const _activeKey = 'family_profile_active_v1';

  Future<List<FamilyProfile>> loadProfiles() async {
    final p = await SharedPreferences.getInstance();
    return _readProfilesList(p);
  }

  static List<FamilyProfile> _readProfilesList(SharedPreferences p) {
    final raw = p.getStringList(_key);
    if (raw == null || raw.isEmpty) {
      return const [
        FamilyProfile(id: 'p1', displayName: 'Default', avatarEmoji: '*'),
      ];
    }
    return raw.map((line) {
      final parts = line.split('|');
      return FamilyProfile(
        id: parts[0],
        displayName: parts.length > 1 ? parts[1] : parts[0],
        avatarEmoji: parts.length > 2 ? parts[2] : 'U',
      );
    }).toList();
  }

  /// 한 번의 [SharedPreferences] 오픈으로 목록·활성 ID를 읽어 초기 로딩을 줄입니다.
  Future<({List<FamilyProfile> profiles, String? activeId})> loadProfilesScreenState({
    int maxProfiles = 5,
  }) async {
    final p = await SharedPreferences.getInstance();
    var list = _readProfilesList(p);
    if (list.length > maxProfiles) {
      list = list.take(maxProfiles).toList();
      final lines = list
          .map((e) => '${e.id}|${e.displayName}|${e.avatarEmoji}')
          .toList();
      await p.setStringList(_key, lines);
    }
    var active = p.getString(_activeKey);
    if (active != null && list.every((e) => e.id != active)) {
      active = null;
    }
    if (active == null && list.isNotEmpty) {
      active = list.first.id;
      await p.setString(_activeKey, active);
    }
    return (profiles: list, activeId: active);
  }

  Future<void> saveProfiles(List<FamilyProfile> profiles) async {
    final p = await SharedPreferences.getInstance();
    final lines = profiles
        .map((e) => '${e.id}|${e.displayName}|${e.avatarEmoji}')
        .toList();
    await p.setStringList(_key, lines);
  }

  Future<String?> activeProfileId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_activeKey);
  }

  Future<void> setActiveProfileId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_activeKey, id);
  }
}
