import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/core/services/prescription_register_parser.dart';

void main() {
  group('PrescriptionRegisterParser', () {
    test('parseFromModelText reads JSON array', () {
      const raw = '```json\n["케피람정100mg","토파맥스정25mg"]\n```';
      final names = PrescriptionRegisterParser.parseFromModelText(raw);
      expect(names.length, 2);
      expect(names.first, contains('케피람'));
    });

    test('parseFromPastedText picks drug lines', () {
      const text = '''
병원: 인하대
케피람정 100mg 1일 2회
토파맥스정 25mg 1일 1회
''';
      final names = PrescriptionRegisterParser.parseFromPastedText(text);
      expect(names.length, greaterThanOrEqualTo(2));
    });
  });
}
