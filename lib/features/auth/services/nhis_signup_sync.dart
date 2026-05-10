import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/domain/result.dart';
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
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

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

    final msg = result is Failure<String> ? result.error.message : 'nhis_error';
    await UserLocalRepository.updateNhisSyncStatus(
      phoneDigits,
      ok: false,
      errorMessage: msg,
    );
    return NhisSignupSyncResult.failed;
  }
}
