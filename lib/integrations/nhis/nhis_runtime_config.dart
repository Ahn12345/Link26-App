import 'package:flutter/foundation.dart';
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
    final list = baseUrlCandidates;
    if (list.isNotEmpty) return list.first;
    return '';
  }

  /// BFF 베이스 URL 목록. `NHIS_BASE_URL`에 쉼표·세미콜론·공백으로 여러 개를 두면
  /// [Link26BffIntegrationsClient] 가 연결 실패 시 순서대로 재시도합니다.
  ///
  /// **릴리스(`kReleaseMode`)**: `assets/env/dotenv`의 LAN 주소는 스토어에 실수로
  /// 포함되기 쉬우므로 무시합니다. 대신 빌드 시
  /// `--dart-define=NHIS_PRODUCTION_BASE_URL=https://운영-API` 만 사용합니다.
  /// 디버그·프로파일은 기존처럼 dotenv → `NHIS_BASE_URL` dart-define 순입니다.
  static List<String> get baseUrlCandidates {
    if (kReleaseMode) {
      final prod = _splitAndNormalizeBffBases(ApiConfig.nhisProductionBaseUrl.trim());
      if (prod.isNotEmpty) return prod;
      return const [];
    }
    final v = _stripQuotes(dotenv.env['NHIS_BASE_URL']);
    if (v.isNotEmpty) return _splitAndNormalizeBffBases(v);
    return _splitAndNormalizeBffBases(ApiConfig.nhisBaseUrl.trim());
  }

  static List<String> _splitAndNormalizeBffBases(String raw) {
    if (raw.isEmpty) return const [];
    final parts = raw.split(RegExp(r'[\s,;]+'));
    final out = <String>[];
    for (final p in parts) {
      var s = p.trim();
      if (s.isEmpty) continue;
      while (s.endsWith('/')) {
        s = s.substring(0, s.length - 1);
      }
      if (s.isNotEmpty) out.add(s);
    }
    return out;
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

  /// BFF `/v1/medications?connectedId=` 용. `NHIS_CODEF_CONNECTED_ID` 우선, 없으면 `CODEF_CONNECTED_ID`.
  static String? get codefConnectedIdForMedications {
    final a = _stripQuotes(dotenv.env['NHIS_CODEF_CONNECTED_ID']);
    if (a.isNotEmpty) return a;
    final b = _stripQuotes(dotenv.env['CODEF_CONNECTED_ID']);
    if (b.isNotEmpty) return b;
    return null;
  }

  /// 기본 **끔**. 홈 부팅·당겨서 새로고침 시 복약 동기화 스낵바(연동 안내)를 보려면 `.env`에
  /// `NHIS_SHOW_SYNC_SNACKBARS=true` 를 넣으세요.
  static bool get showMedicationSyncSnackbars {
    final s = _stripQuotes(dotenv.env['NHIS_SHOW_SYNC_SNACKBARS']).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
}
