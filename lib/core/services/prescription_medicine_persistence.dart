import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/core/services/user_pinned_medicine_store.dart';
import 'package:link26_app/models/medicine.dart';

/// 처방전·수동 등록 약을 로컬 목록·캐시·핀에 함께 반영합니다.
abstract final class PrescriptionMedicinePersistence {
  static Medicine stub(String name) => Medicine(
        name: name.trim(),
        dose: '-',
        frequency: '-',
        time: '09:00',
      );

  static Future<int> saveAll(Iterable<Medicine> medicines) async {
    var count = 0;
    for (final m in medicines) {
      final name = m.name.trim();
      if (name.isEmpty) continue;
      await UserPinnedMedicineStore.pin(name);
      await LocalMedicineListStore.add(name);
      await NhisMedicineCacheStore.upsert(m);
      count++;
    }
    return count;
  }
}
