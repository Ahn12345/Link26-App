import 'dart:convert';

import 'package:test/test.dart';
import 'package:link26_app/integrations/codef/codef_medication_mapper.dart';

void main() {
  test('flat data.list with English keys', () {
    final root = {
      'data': {
        'list': [
          {'drugName': '아스피린', 'dosage': '1정', 'frequency': '1일 1회'},
        ],
      },
    };
    final items = codefRootToMedicationItems(root);
    expect(items.length, 1);
    expect(items.first['name'], '아스피린');
    expect(items.first['dose'], '1정');
  });

  test('data as JSON string with nested res', () {
    final inner = {
      'res': {
        'drugInfoList': [
          {'약품명': '타이레놀', '일투': '2정'},
        ],
      },
    };
    final root = {
      'data': jsonEncode(inner),
    };
    final items = codefRootToMedicationItems(root);
    expect(items.length, 1);
    expect(items.first['name'], '타이레놀');
    expect(items.first['dose'], '2정');
  });

  test('deep nested map without standard list key', () {
    final root = {
      'data': {
        'wrapper': {
          'history': [
            {
              'meta': {'id': 1},
              '처방약품명': '오메프라졸',
              '복약횟수': '2회',
            },
          ],
        },
      },
    };
    final items = codefRootToMedicationItems(root);
    expect(items.length, 1);
    expect(items.first['name'], '오메프라졸');
    expect(items.first['frequency'], '2회');
  });

  test('Tilko NHIS detail list shape (ChoBangYakPumMyung)', () {
    final root = {
      'data': {
        'RetrieveTreatmentInjectionInformationPersonDetailList': [
          {'ChoBangYakPumMyung': '아목시실린', 'TuyakIlSoo': '1일 3회'},
        ],
      },
    };
    final items = codefRootToMedicationItems(root);
    expect(items.length, 1);
    expect(items.first['name'], '아목시실린');
    expect(items.first['frequency'], '1일 3회');
  });

  test('dedupes identical rows', () {
    final root = {
      'data': {
        'list': [
          {'itemName': '비타민', 'dosage': '1정'},
          {'itemName': '비타민', 'dosage': '1정'},
        ],
      },
    };
    final items = codefRootToMedicationItems(root);
    expect(items.length, 1);
  });
}
