import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/constants/api_keys.dart';

/// `.env` 우선, 없으면 빌드 시 [ApiConfig.nhisBaseUrl] (`--dart-define=NHIS_BASE_URL=...`).
abstract final class NhisRuntimeConfig {
  static String _stripQuotes(String? raw) {
    var v = (raw ?? '').trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }

  /// `true`이면 NHIS/BFF **HTTP 호출 없이** 목 응답으로 연동만 검증합니다. 실서버 준비 후 `false`.
  static bool get useMock {
    final s = _stripQuotes(dotenv.env['NHIS_USE_MOCK']).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static String get baseUrl {
    final v = _stripQuotes(dotenv.env['NHIS_BASE_URL']);
    if (v.isNotEmpty) return v;
    return ApiConfig.nhisBaseUrl.trim();
  }

  /// 회원가입 연동 POST 경로 (자체 BFF·공단 프록시 등 스펙에 맞게 변경).
  static String get signupPath {
    final p = _stripQuotes(dotenv.env['NHIS_SIGNUP_PATH']);
    if (p.isNotEmpty) return p.startsWith('/') ? p : '/$p';
    return '/v1/signup';
  }

  /// 로그인(세션) 연동 POST 경로.
  static String get loginPath {
    final p = _stripQuotes(dotenv.env['NHIS_LOGIN_PATH']);
    if (p.isNotEmpty) return p.startsWith('/') ? p : '/$p';
    return '/v1/login';
  }

  /// 복약·약 목록 GET 경로 (쿼리 `phone` 등은 클라이언트에서 붙임).
  static String get medicinesPath {
    final p = _stripQuotes(dotenv.env['NHIS_MEDICINES_PATH']);
    if (p.isNotEmpty) return p.startsWith('/') ? p : '/$p';
    return '/v1/medications';
  }

  /// 공공데이터포털 등 `serviceKey` 쿼리가 필요할 때.
  static String? get serviceKey {
    final k = _stripQuotes(dotenv.env['NHIS_SERVICE_KEY']);
    if (k.isEmpty) return null;
    return k;
  }

  /// `true`이면 NHIS 전송 실패 시 로컬 가입 롤백 후 화면 유지.
  static bool get signupRequired {
    final s = _stripQuotes(dotenv.env['NHIS_SIGNUP_REQUIRED']).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  /// `true`이면 NHIS 로그인 연동 실패 시 홈으로 진입하지 않습니다.
  static bool get loginRequired {
    final s = _stripQuotes(dotenv.env['NHIS_LOGIN_REQUIRED']).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
}
