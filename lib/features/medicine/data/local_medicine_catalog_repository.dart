import 'package:flutter/foundation.dart';
import 'package:link26_app/domain/domain.dart';

/// 데모용 로컬 카탈로그. 이후 API·로컬 DB로 교체합니다.
final class LocalMedicineCatalogRepository implements MedicineCatalogRepository {
  const LocalMedicineCatalogRepository();

  static const List<MedicineProduct> _demo = [
    MedicineProduct(
      id: 'demo-1',
      name: 'Acetaminophen',
      dosageHint: 'Max 4g/day — follow label',
    ),
    MedicineProduct(
      id: 'demo-2',
      name: 'Vitamin D',
      dosageHint: 'With food',
    ),
    MedicineProduct(
      id: 'demo-3',
      name: 'Omeprazole',
      dosageHint: 'Before breakfast',
    ),
  ];

  @override
  Future<List<MedicineProduct>> listKnown() {
    return SynchronousFuture<List<MedicineProduct>>(List.unmodifiable(_demo));
  }
}
