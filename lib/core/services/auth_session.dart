import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// 로컬 세션(실제 서버 로그인 전까지 스텁).
abstract final class AuthSession {
  static Future<bool> isSignedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(StorageKeys.sessionSignedInV1) ?? false;
  }

  static Future<void> signIn() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StorageKeys.sessionSignedInV1, true);
  }

  static Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.sessionSignedInV1);
  }
}
