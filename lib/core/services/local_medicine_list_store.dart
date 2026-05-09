import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

abstract final class LocalMedicineListStore {
  static Future<List<String>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(StorageKeys.localMyMedicinesJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => '$e').toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<String> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(StorageKeys.localMyMedicinesJson, jsonEncode(items));
  }

  static Future<void> add(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final cur = await load();
    if (cur.contains(n)) return;
    cur.add(n);
    await save(cur);
  }

  static Future<void> remove(String name) async {
    final cur = await load()..remove(name);
    await save(cur);
  }
}
