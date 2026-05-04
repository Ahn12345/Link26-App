import 'package:shared_preferences/shared_preferences.dart';

/// NHIS 등 연동용 토큰 저장 (실제 키명은 백엔드 스펙에 맞게 조정).
class NhisTokenManager {
  static const _access = 'nhis_access_token_v1';
  static const _refresh = 'nhis_refresh_token_v1';

  Future<String?> readAccess() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_access);
  }

  Future<void> writeAccess(String? token) async {
    final p = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await p.remove(_access);
    } else {
      await p.setString(_access, token);
    }
  }

  Future<String?> readRefresh() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_refresh);
  }

  Future<void> writeRefresh(String? token) async {
    final p = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await p.remove(_refresh);
    } else {
      await p.setString(_refresh, token);
    }
  }
}
