import 'dart:convert';

import 'dur_response_models.dart';

DurCheckResponse? mapDurCheckOrNull(String body) {
  try {
    final map = jsonDecode(body) as Map<String, dynamic>;
    return DurCheckResponse.fromJson(map);
  } catch (_) {
    return null;
  }
}
