import 'dart:convert';

/// 공공·기관 API가 돌려주는 중첩 JSON에서 약 목록 행을 최대한 뽑아냅니다.
/// (파일명·함수명은 예전 CODEF 연동 시절 그대로이며, 틸코 NHIS 응답에도 동일하게 사용합니다.)
/// `data`가 문자열(JSON)·중첩 Map·다양한 키명을 쓰는 경우를 흡수합니다.
List<Map<String, dynamic>> codefRootToMedicationItems(Map<String, dynamic> root) {
  var rows = _extractDataRows(root['data']);
  if (rows.isEmpty) {
    rows = _extractDataRows(root['Data']);
  }
  if (rows.isEmpty) {
    rows = _extractDataRows(root['result']);
  }
  if (rows.isEmpty) {
    rows = _extractDataRows(root['Result']);
  }
  if (rows.isEmpty) {
    for (final k in _tilkoNhisWrapperKeys) {
      final w = root[k];
      if (w is Map) {
        rows = _extractDataRows(w);
        if (rows.isNotEmpty) break;
      }
    }
  }
  if (rows.isEmpty) {
    rows = _extractDataRows(root);
  }
  if (rows.isEmpty) {
    rows = _deepCollectMedicationLikeRows(root);
  }
  return _rowsToMedicationItems(rows);
}

/// 틸코·기관 JSON에서 실 배열이 한 겹 더 감싸진 경우.
const _tilkoNhisWrapperKeys = [
  'Body',
  'body',
  'ResultData',
  'resultData',
  'Response',
  'response',
  'Output',
  'output',
  'OutData',
  'outData',
];

const _listContainerKeys = [
  'list',
  'resList',
  'drugList',
  'medicationList',
  'medicineList',
  'items',
  'resTreatmentList',
  'treatmentList',
  'prescriptionList',
  'medicationTakingList',
  'takingList',
  'drugInfoList',
  'mediList',
  'prescriptionDrugList',
  'treatmentDrugList',
  'medicineTakingInfoList',
  'detailList',
  'historyList',
  'records',
  'rows',
  'outputList',
  'drugInfos',
  'treatments',
  'prescriptions',
  // 틸코 NHIS 공동인증 API 응답 필드 (문서 RetrieveTreatmentInjectionInformationPerson)
  'ResultList',
  'RetrieveTreatmentInjectionInformationPersonDetailList',
  // 틸코 간편인증 [내가 먹는 약] HIRAA050300000100 — 처방 행 안의 약 목록
  'DrugList',
];

const _medicineNameKeys = [
  'name',
  'drugName',
  'medicineName',
  'itemName',
  'resDrugName',
  'resDrugNm',
  'drugNm',
  'mediNm',
  'mediName',
  'drugNameKr',
  'GENERALNM',
  'ITEMNAME',
  'ITEM_NAME',
  'drug_name',
  '약품명',
  '품명',
  '처방약품명',
  '제품명',
  '성분명',
  '보내실약품명',
  '투약약품명',
  // 틸코 NHIS 진료·투약(공동인증) 응답 필드명
  'ChoBangYakPumMyung',
  'MediPrdcNm',
  'ByungEuiwonYakGukMyung',
  // HIRAA050300000100 DrugList
  'Name',
  'PrscNm',
  'PrscPrepNm',
  'GenNm',
  'MediNm',
];

const _doseKeys = [
  'dose',
  'dosage',
  'resDosage',
  '일투',
  '1일투여량',
  '투여량',
  'DosagePerOnce',
  'DailyDose',
];

const _freqKeys = [
  'frequency',
  'resFrequency',
  '복약',
  '복약횟수',
  '횟수',
  'TuyakIlSoo',
];

const _timeKeys = [
  'time',
  'resTime',
  '투약시각',
  '투약시간',
];

List<Map<String, dynamic>> _rowsToMedicationItems(List<Map<String, dynamic>> rows) {
  final out = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final r in rows) {
    final name = _firstNonEmpty(r, _medicineNameKeys);
    if (name.isEmpty) continue;
    final dedupe =
        '${name.trim().toLowerCase()}|${_firstNonEmpty(r, _doseKeys)}|${_firstNonEmpty(r, _freqKeys)}';
    if (seen.contains(dedupe)) continue;
    seen.add(dedupe);
    out.add({
      'name': name,
      'dose': _firstNonEmpty(r, _doseKeys),
      'frequency': _firstNonEmpty(r, _freqKeys),
      'time': _firstNonEmpty(r, _timeKeys),
    });
  }
  return out;
}

Map<String, dynamic> _stringKeyMap(Map raw) {
  final out = <String, dynamic>{};
  for (final e in raw.entries) {
    out['${e.key}'] = e.value;
  }
  return out;
}

List<Map<String, dynamic>> _extractDataRows(dynamic data) {
  if (data == null) return [];
  if (data is String) {
    final s = data.trim();
    if (s.isEmpty) return [];
    try {
      return _extractDataRows(jsonDecode(s));
    } catch (_) {
      return [];
    }
  }
  if (data is List) {
    final out = <Map<String, dynamic>>[];
    for (final e in data) {
      if (e is Map) {
        final m = _stringKeyMap(e);
        if (_mapLooksLikeMedicationRow(m)) {
          out.add(m);
        } else {
          out.addAll(_extractDataRows(e));
        }
      } else {
        out.addAll(_extractDataRows(e));
      }
    }
    return out;
  }
  if (data is Map) {
    final m = _stringKeyMap(data);
    for (final key in _listContainerKeys) {
      final v = m[key];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => _stringKeyMap(e))
            .toList();
      }
    }
    for (final key in [
      'res',
      'output',
      'outData',
      'body',
      'content',
      'detail',
      'Body',
      'ResultData',
      'ResData',
      'Response',
      'resultData',
    ]) {
      final v = m[key];
      if (v != null) {
        final inner = _extractDataRows(v);
        if (inner.isNotEmpty) return inner;
      }
    }
  }
  return [];
}

bool _mapLooksLikeMedicationRow(Map<String, dynamic> m) {
  return _firstNonEmpty(m, _medicineNameKeys).isNotEmpty;
}

/// JSON 전체를 깊이 우선 탐색해 약품명 필드가 있는 Map만 모읍니다 (스키마 미문서 대응).
List<Map<String, dynamic>> _deepCollectMedicationLikeRows(
  Map<String, dynamic> root, {
  int maxDepth = 18,
}) {
  final out = <Map<String, dynamic>>[];
  void walk(dynamic node, int depth) {
    if (depth > maxDepth) return;
    if (node is Map) {
      final m = _stringKeyMap(node);
      if (_mapLooksLikeMedicationRow(m)) {
        out.add(m);
      }
      for (final v in m.values) {
        walk(v, depth + 1);
      }
    } else if (node is List) {
      for (final e in node) {
        walk(e, depth + 1);
      }
    } else if (node is String) {
      final s = node.trim();
      if (s.length > 2 && (s.startsWith('[') || s.startsWith('{'))) {
        try {
          walk(jsonDecode(s), depth + 1);
        } catch (_) {}
      }
    }
  }

  walk(root, 0);
  return out;
}

String _firstNonEmpty(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = '$v'.trim();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return '';
}
