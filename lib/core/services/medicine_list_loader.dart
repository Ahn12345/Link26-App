import 'package:link26_app/core/constants/link26_medication_feature_flags.dart';
import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/medication_display_filter.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/core/services/user_pinned_medicine_store.dart';
import 'package:link26_app/models/medicine.dart';

/// 캐시·수동 목록 병합 후, 선택 시 병원 수액·주사 항목을 제외합니다.
abstract final class MedicineListLoader {
  static String normName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static Future<List<Medicine>> loadMerged({
    bool hideHospitalSupplies = false,
  }) async {
    final cached = await NhisMedicineCacheStore.loadMedicines();
    final manualNames = await LocalMedicineListStore.load();
    final byName = <String, Medicine>{};
    for (final m in cached) {
      final k = normName(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final n in manualNames) {
      final k = normName(n);
      if (k.isEmpty) continue;
      byName.putIfAbsent(
        k,
        () => Medicine(name: n.trim(), dose: '-', frequency: '-', time: '-'),
      );
    }
    var merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // 틸코·심평원 API 중단 시: 수동·처방전 등록 약만 표시 (예전 서버 57건 숨김)
    if (!Link26MedicationFeatureFlags.tilkoHiraRemoteSyncEnabled) {
      final pinned = await UserPinnedMedicineStore.loadNorms();
      final manualNorms = manualNames.map(normName).where((k) => k.isNotEmpty);
      final allowed = {...pinned, ...manualNorms};
      if (allowed.isEmpty) {
        merged = [];
      } else {
        merged = [
          for (final m in merged)
            if (allowed.contains(normName(m.name))) m,
        ];
        final have = merged.map((m) => normName(m.name)).toSet();
        for (final n in manualNames) {
          final k = normName(n);
          if (k.isEmpty || have.contains(k)) continue;
          merged.add(
            Medicine(name: n.trim(), dose: '-', frequency: '-', time: '-'),
          );
          have.add(k);
        }
        merged.sort((a, b) => a.name.compareTo(b.name));
      }
    }

    if (!hideHospitalSupplies) return merged;
    return MedicationDisplayFilter.filterForDailyOralView(merged);
  }
}
