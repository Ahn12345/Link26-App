/// 앱 전역에서 쓰는 의약품(또는 건강기능식품) 식별용 엔티티.
class MedicineProduct {
  const MedicineProduct({
    required this.id,
    required this.name,
    this.dosageHint,
  });

  final String id;
  final String name;
  final String? dosageHint;
}
