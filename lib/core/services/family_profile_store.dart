import 'package:shared_preferences/shared_preferences.dart';

/// 넷플릭스 스타일 로컬 프로필(서버 동기화는 추후).
class FamilyProfile {
  const FamilyProfile({
    required this.id,
    required this.displayName,
    this.avatarEmoji = '👤',
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
    final raw = p.getStringList(_key);
    if (raw == null || raw.isEmpty) {
      return const [
        FamilyProfile(id: 'p1', displayName: '기본', avatarEmoji: '🙂'),
      ];
    }
    return raw.map((line) {
      final parts = line.split('|');
      return FamilyProfile(
        id: parts[0],
        displayName: parts.length > 1 ? parts[1] : parts[0],
        avatarEmoji: parts.length > 2 ? parts[2] : '👤',
      );
    }).toList();
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
