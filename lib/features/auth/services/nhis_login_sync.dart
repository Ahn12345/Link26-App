import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
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

    if (NhisRuntimeConfig.useMock) {
      if (kDebugMode) {
        debugPrint('NHIS login: 목(mock) 성공 — 네트워크 미사용');
      }
      await UserLocalRepository.updateNhisSyncStatus(
        user.phoneDigits,
        ok: true,
        errorMessage: 'mock',
      );
      return NhisLoginSyncResult.success;
    }

    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      return NhisLoginSyncResult.skipped;
    }

    final hash = user.residentRegistrationHash ?? '';
    if (hash.isEmpty) {
      // 가입 경로 외 계정·구버전 DB 등: NHIS POST 없이 로컬 로그인만 허용
      return NhisLoginSyncResult.skipped;
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

    final msg = result is Failure<String>
        ? nhisHttpUserMessage(result.error)
        : 'nhis_error';
    if (kDebugMode) {
      debugPrint(
        'NHIS login POST 실패: $msg (base=${NhisRuntimeConfig.baseUrl} path=${NhisRuntimeConfig.loginPath})',
      );
    }
    await UserLocalRepository.updateNhisSyncStatus(
      user.phoneDigits,
      ok: false,
      errorMessage: msg,
    );
    return NhisLoginSyncResult.failed;
  }
}
