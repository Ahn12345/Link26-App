import 'dart:convert';

import '../../core/domain/result.dart';
import 'simple_auth_api_client.dart';
import 'simple_auth_request_models.dart';
import 'simple_auth_response_models.dart';

/// 간편인증 시작 URL 조회.
Future<SimpleAuthStartResponse?> fetchAuthStart(SimpleAuthApiClient client) async {
  const req = SimpleAuthStartRequest(redirectUri: 'link26app://callback');
  final res = await client.startRaw(req);
  return res.fold(
    onSuccess: (body) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        return SimpleAuthStartResponse.fromJson(map);
      } catch (_) {
        return null;
      }
    },
    onFailure: (_) => null,
  );
}
