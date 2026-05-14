import 'package:flutter/foundation.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/nhis/nhis_signup_client.dart';

enum NhisSignupSyncResult { skipped, success, failed }

/// 로컬 DB 저장 후 NHIS(또는 BFF)로 동일 회원 정보를 전송합니다.
abstract final class NhisSignupSync {
  static Future<NhisSignupSyncResult> syncAfterLocalRegister({
    required String displayName,
    required String phoneDigits,
    required String gender,
    required String residentRegistrationHash,
  }) async {
    if (NhisRuntimeConfig.useMock) {
      if (kDebugMode) {
        debugPrint('NHIS signup: 목(mock) 성공 — 네트워크 미사용');
      }
      await UserLocalRepository.updateNhisSyncStatus(
        phoneDigits,
        ok: true,
        errorMessage: 'mock',
      );
      return NhisSignupSyncResult.success;
    }

    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      return NhisSignupSyncResult.skipped;
    }

    final client = NhisSignupClient();
    final result = await client.submitRegistration(
      displayName: displayName,
      phoneDigits: phoneDigits,
      gender: gender,
      residentRegistrationHash: residentRegistrationHash,
    );

    if (result is Success<String>) {
      await UserLocalRepository.updateNhisSyncStatus(
        phoneDigits,
        ok: true,
        errorMessage: null,
      );
      return NhisSignupSyncResult.success;
    }

    final msg = result is Failure<String>
        ? nhisHttpUserMessage(result.error)
        : 'nhis_error';
    if (result is Failure<String> &&
        nhisFailureLooksLikeUnreachableHost(result.error) &&
        !NhisRuntimeConfig.signupRequired) {
      if (kDebugMode) {
        debugPrint(
          'NHIS signup POST 생략(연결 불가·로컬만): $msg',
        );
      }
      return NhisSignupSyncResult.skipped;
    }
    if (kDebugMode) {
      debugPrint(
        'NHIS signup POST 실패: $msg (base=${NhisRuntimeConfig.baseUrl} path=${NhisRuntimeConfig.signupPath})',
      );
    }
    await UserLocalRepository.updateNhisSyncStatus(
      phoneDigits,
      ok: false,
      errorMessage: msg,
    );
    return NhisSignupSyncResult.failed;
  }
}
