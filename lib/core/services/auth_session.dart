import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// 로컬 세션(실제 서버 로그인 전까지 스텁).
abstract final class AuthSession {
  static Future<bool> isSignedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(StorageKeys.sessionSignedInV1) ?? false;
  }

  static Future<void> signIn({required String phoneDigits}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StorageKeys.sessionSignedInV1, true);
    await p.setString(StorageKeys.sessionActivePhoneV1, phoneDigits);
  }

  static Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.sessionSignedInV1);
    await p.remove(StorageKeys.sessionActivePhoneV1);
  }

  /// 현재 세션에 묶인 로컬 사용자 전화번호(숫자만). 없으면 null.
  static Future<String?> activePhoneDigits() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(StorageKeys.sessionActivePhoneV1);
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
