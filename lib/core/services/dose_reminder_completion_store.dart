import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:link26_app/core/constants/storage_keys.dart';

/// 홈·알림 센터 「복용 완료」 상태 — 일 단위로 약 이름(정규화)을 저장합니다.
abstract final class DoseReminderCompletionStore {
  static String _norm(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static String _todayKey() {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final mo = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$mo-$d';
  }

  static Future<Map<String, List<String>>> _loadRaw() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(StorageKeys.doseReminderCompletedByDayV1);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) {
        final list = v is List ? v.map((e) => '$e').toList() : <String>[];
        return MapEntry(k, list);
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveRaw(Map<String, List<String>> map) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      StorageKeys.doseReminderCompletedByDayV1,
      jsonEncode(map),
    );
  }

  static Future<Set<String>> completedNormsToday() async {
    final all = await _loadRaw();
    final day = _todayKey();
    final list = all[day] ?? [];
    return list.map(_norm).where((s) => s.isNotEmpty).toSet();
  }

  /// [fromInclusive]·[toInclusive] 의 **날짜**만 사용합니다(시각 무시).
  static Future<Map<String, int>> completionCountsByNormInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final all = await _loadRaw();
    final a = DateTime(
      fromInclusive.year,
      fromInclusive.month,
      fromInclusive.day,
    );
    final b = DateTime(
      toInclusive.year,
      toInclusive.month,
      toInclusive.day,
    );
    final counts = <String, int>{};
    for (final e in all.entries) {
      final day = _parseDayKey(e.key);
      if (day == null) continue;
      if (day.isBefore(a) || day.isAfter(b)) continue;
      for (final name in e.value) {
        final k = _norm(name);
        if (k.isEmpty) continue;
        counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    return counts;
  }

  static DateTime? _parseDayKey(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final mo = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || mo == null || d == null) return null;
    return DateTime(y, mo, d);
  }

  static Future<void> markCompleted(String medicineName) async {
    final k = _norm(medicineName);
    if (k.isEmpty) return;
    final all = await _loadRaw();
    final day = _todayKey();
    final cur = List<String>.from(all[day] ?? []);
    if (!cur.contains(k)) {
      cur.add(k);
      all[day] = cur;
      await _saveRaw(all);
    }
  }

  /// CODEF 등으로 복약 목록이 권위 있게 갱신될 때 당일 완료 체크를 초기화합니다.
  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.doseReminderCompletedByDayV1);
  }
}
