import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// 사용자가 직접 추가한 약 — 심평원 전체 동기화 시에도 목록에서 제거하지 않습니다.
abstract final class UserPinnedMedicineStore {
  static String norm(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static Future<Set<String>> loadNorms() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(StorageKeys.userPinnedMedicineNormsJson);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => '$e').where((s) => s.isNotEmpty).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> pin(String name) async {
    final k = norm(name);
    if (k.isEmpty) return;
    final set = await loadNorms();
    if (set.contains(k)) return;
    set.add(k);
    await _save(set);
  }

  static Future<void> unpin(String name) async {
    final k = norm(name);
    if (k.isEmpty) return;
    final set = await loadNorms();
    if (!set.remove(k)) return;
    await _save(set);
  }

  static Future<void> _save(Set<String> norms) async {
    final p = await SharedPreferences.getInstance();
    final sorted = norms.toList()..sort();
    await p.setString(
      StorageKeys.userPinnedMedicineNormsJson,
      jsonEncode(sorted),
    );
  }
}
