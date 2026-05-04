import '../entities/medicine_product.dart';

/// 처방·복약 목록 등 카탈로그 소스 추상화.
abstract class MedicineCatalogRepository {
  Future<List<MedicineProduct>> listKnown();
}
