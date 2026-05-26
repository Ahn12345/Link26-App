import 'package:link26_app/models/medicine.dart';

/// 심평원·건보 동기화 목록에서 병원 수액·주사 등을 걸러 복용 약 위주로 보기 위한 휴리스틱.
abstract final class MedicationDisplayFilter {
  static final _injectablePattern = RegExp(
    r'주사|주사액|주사제|용액|수액|정맥|근육|피하|'
    r'\bIV\b|Inj\.?|Injection|infusion|infus',
    caseSensitive: false,
  );

  static final _fluidPattern = RegExp(
    r'\d+\s*mL|\bml\b|백\b|생리식염|하트만|포도당|링거|'
    r'sodium\s*chloride|hartmann|dextrose|glucose\s*solution',
    caseSensitive: false,
  );

  static bool isLikelyHospitalSupplyOrInjectable(String name) {
    final n = name.trim();
    if (n.isEmpty) return false;
    if (_injectablePattern.hasMatch(n)) return true;
    if (_fluidPattern.hasMatch(n)) return true;
    return false;
  }

  static List<Medicine> filterForDailyOralView(List<Medicine> items) => [
        for (final m in items)
          if (!isLikelyHospitalSupplyOrInjectable(m.name)) m,
      ];
}
