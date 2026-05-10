import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/nhis/nhis_signup_client.dart';

enum NhisLoginSyncResult { skipped, success, failed }

/// 로컬 DB에서 불러온 사용자로 NHIS(또는 BFF) 로그인·세션 연동을 호출합니다.
abstract final class NhisLoginSync {
  static Future<NhisLoginSyncResult> syncAfterLocalLogin({
    required LocalUserRecord user,
  }) async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      return NhisLoginSyncResult.skipped;
    }

    final hash = user.residentRegistrationHash ?? '';
    if (hash.isEmpty) {
      await UserLocalRepository.updateNhisSyncStatus(
        user.phoneDigits,
        ok: false,
        errorMessage: 'missing_resident_registration_hash',
      );
      return NhisLoginSyncResult.failed;
    }

    final client = NhisSignupClient();
    final result = await client.submitLogin(
      displayName: user.displayName,
      phoneDigits: user.phoneDigits,
      gender: user.gender.isEmpty ? 'unknown' : user.gender,
      residentRegistrationHash: hash,
    );

    if (result is Success<String>) {
      await UserLocalRepository.updateNhisSyncStatus(
        user.phoneDigits,
        ok: true,
        errorMessage: null,
      );
      return NhisLoginSyncResult.success;
    }

    final msg = result is Failure<String> ? result.error.message : 'nhis_error';
    await UserLocalRepository.updateNhisSyncStatus(
      user.phoneDigits,
      ok: false,
      errorMessage: msg,
    );
    return NhisLoginSyncResult.failed;
  }
}
