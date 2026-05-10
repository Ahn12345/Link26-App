import 'package:dio/dio.dart';

import '../../core/domain/failure.dart';

/// NHIS/BFF 호출 실패 시 사용자·로그용 짧은 설명.
String nhisHttpUserMessage(AppFailure failure) {
  final c = failure.cause;
  if (c is DioException) {
    switch (c.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '연결 시간 초과 — 서버가 응답하는지, Wi‑Fi/데이터를 확인하세요.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없음 — NHIS_BASE_URL(또는 BFF 주소), '
            '에뮬레이터면 PC는 http://10.0.2.2:포트, http 는 디버그 빌드 필요';
      case DioExceptionType.badCertificate:
        return 'SSL 인증서 오류 — https 주소·기업용 인증서를 확인하세요.';
      case DioExceptionType.badResponse:
        final code = c.response?.statusCode;
        return code != null
            ? '서버 응답 $code — 경로·JSON 스펙이 BFF와 맞는지 확인하세요.'
            : '서버 오류 응답 — BFF 로그를 확인하세요.';
      default:
        break;
    }
  }
  return failure.message;
}
