import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// 로컬 세션(실제 서버 로그인 전까지 스텁).
abstract final class AuthSession {
  static Future<bool> isSignedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(StorageKeys.sessionSignedInV1) ?? false;
  }

  static Future<void> signIn({
    required String phoneDigits,
    int? localUserId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StorageKeys.sessionSignedInV1, true);
    final norm = phoneDigits.replaceAll(RegExp(r'\D'), '');
    await p.setString(StorageKeys.sessionActivePhoneV1, norm);
    if (localUserId != null && localUserId > 0) {
      await p.setInt(StorageKeys.sessionLocalUserIdV1, localUserId);
    }
  }

  static Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.sessionSignedInV1);
    await p.remove(StorageKeys.sessionActivePhoneV1);
    await p.remove(StorageKeys.sessionLocalUserIdV1);
  }

  /// [users] 테이블 PK. [signIn] 시 넘기지 않았으면 null.
  static Future<int?> activeLocalUserId() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(StorageKeys.sessionLocalUserIdV1);
    if (v == null || v <= 0) return null;
    return v;
  }

  /// 현재 세션에 묶인 로컬 사용자 전화번호(숫자만). 없으면 null.
  static Future<String?> activePhoneDigits() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(StorageKeys.sessionActivePhoneV1);
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
