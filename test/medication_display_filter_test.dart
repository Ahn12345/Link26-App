import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/core/services/medication_display_filter.dart';
import 'package:link26_app/models/medicine.dart';

void main() {
  group('MedicationDisplayFilter', () {
    test('flags injectables and fluids', () {
      expect(
        MedicationDisplayFilter.isLikelyHospitalSupplyOrInjectable(
          '생리식염 500mL 백',
        ),
        isTrue,
      );
      expect(
        MedicationDisplayFilter.isLikelyHospitalSupplyOrInjectable(
          '케피람정 100mg',
        ),
        isFalse,
      );
      expect(
        MedicationDisplayFilter.isLikelyHospitalSupplyOrInjectable(
          '알다틴정 25mg',
        ),
        isFalse,
      );
    });

    test('filterForDailyOralView keeps oral meds', () {
      final items = [
        const Medicine(
          name: '생리식염 500mL',
          dose: '-',
          frequency: '-',
          time: '-',
        ),
        const Medicine(
          name: '알다틴정',
          dose: '-',
          frequency: '-',
          time: '-',
        ),
      ];
      final out = MedicationDisplayFilter.filterForDailyOralView(items);
      expect(out.length, 1);
      expect(out.first.name, '알다틴정');
    });
  });
}
