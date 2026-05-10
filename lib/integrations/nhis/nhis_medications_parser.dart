import 'dart:convert';

import '../../models/medicine.dart';

/// BFF·게이트웨이 응답에서 약 목록 추출 (스키마는 백엔드에 맞게 확장).
abstract final class NhisMedicationsParser {
  static List<Medicine> parseResponseBody(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    final dynamic decoded = jsonDecode(trimmed);

    if (decoded is List) {
      return _fromList(decoded);
    }
    if (decoded is Map<String, dynamic>) {
      final m = decoded;
      if (m['items'] is List) return _fromList(m['items'] as List);
      if (m['medications'] is List) return _fromList(m['medications'] as List);
      if (m['data'] is List) return _fromList(m['data'] as List);
      if (m['medicines'] is List) {
        final list = m['medicines'] as List;
        if (list.isNotEmpty && list.first is String) {
          return list
              .map((e) => Medicine(
                    name: '$e',
                    dose: '-',
                    frequency: '-',
                    time: '-',
                  ))
              .where((x) => x.name.trim().isNotEmpty)
              .toList();
        }
        return _fromList(list);
      }
    }
    return [];
  }

  static List<Medicine> _fromList(List<dynamic> list) {
    final out = <Medicine>[];
    for (final e in list) {
      if (e is String) {
        final n = e.trim();
        if (n.isNotEmpty) {
          out.add(Medicine(name: n, dose: '-', frequency: '-', time: '-'));
        }
        continue;
      }
      if (e is Map) {
        final map = Map<String, dynamic>.from(e);
        final name = '${map['name'] ?? map['drugName'] ?? map['itemName'] ?? ''}'
            .trim();
        if (name.isEmpty) continue;
        out.add(Medicine.fromJson(map));
      }
    }
    return out;
  }
}
