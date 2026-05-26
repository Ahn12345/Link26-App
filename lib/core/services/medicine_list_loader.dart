import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/medication_display_filter.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
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
    final merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (!hideHospitalSupplies) return merged;
    return MedicationDisplayFilter.filterForDailyOralView(merged);
  }
}
