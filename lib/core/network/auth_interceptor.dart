import 'nhis_token_manager.dart';

/// Authorization 헤더 빌더.
class AuthHeaderBuilder {
  AuthHeaderBuilder(this._tokens);

  final NhisTokenManager _tokens;

  Future<Map<String, String>> headers({Map<String, String>? extra}) async {
    final t = await _tokens.readAccess();
    final h = <String, String>{
      'Accept': 'application/json',
      ...?extra,
    };
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }
}
