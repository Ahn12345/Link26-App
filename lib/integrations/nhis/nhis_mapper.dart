import 'dart:convert';

import 'nhis_response_models.dart';

NhisUserProfile? mapUserProfileOrNull(String body) {
  try {
    final map = jsonDecode(body) as Map<String, dynamic>;
    return NhisUserProfile.fromJson(map);
  } catch (_) {
    return null;
  }
}
