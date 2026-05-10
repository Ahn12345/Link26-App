import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../../models/medicine.dart';

/// 홈·검색과 공유하는 약 목록 캐시 (NHIS/BFF 동기화 + 시트에서 수동 추가).
abstract final class NhisMedicineCacheStore {
  static String _norm(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static Future<List<Medicine>> loadMedicines() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(StorageKeys.nhisSyncedMedicinesJsonV1);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Medicine.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((m) => m.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMedicines(List<Medicine> items) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((m) => m.toJson()).toList());
    await p.setString(StorageKeys.nhisSyncedMedicinesJsonV1, encoded);
  }

  static Future<void> upsert(Medicine m) async {
    final name = m.name.trim();
    if (name.isEmpty) return;
    final list = await loadMedicines();
    final key = _norm(name);
    final idx = list.indexWhere((x) => _norm(x.name) == key);
    if (idx >= 0) {
      list[idx] = m;
    } else {
      list.add(m);
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    await saveMedicines(list);
  }
}
