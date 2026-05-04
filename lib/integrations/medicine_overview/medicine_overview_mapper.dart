import 'dart:convert';

import 'medicine_overview_response_models.dart';

List<MedicineSummary> mapMedicineList(String body) {
  try {
    final list = jsonDecode(body) as List<dynamic>;
    return list
        .map((e) => MedicineSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}
