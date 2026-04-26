import 'package:shared_preferences/shared_preferences.dart';

/// 메인 화면에 표시할 블록 ID 저장.
class HomeLayoutStore {
  HomeLayoutStore._();

  static const _key = 'home_layout_block_ids_v1';

  static const allBlockIds = <String>{
    'logo',
    'title',
    'subtitle',
    'quickActions',
    'familySummary',
  };

  static Future<Set<String>> loadVisible() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key);
    if (list == null || list.isEmpty) {
      return {...allBlockIds};
    }
    final set = list.toSet();
    return set.intersection(allBlockIds).isEmpty ? {...allBlockIds} : set;
  }

  static Future<void> saveVisible(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    final filtered = ids.intersection(allBlockIds);
    await p.setStringList(_key, filtered.toList());
  }
}
