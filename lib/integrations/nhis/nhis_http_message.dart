import 'dart:async';
import 'dart:io';

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
        return '서버에 연결할 수 없습니다. '
            '실제 폰: NHIS_BASE_URL을 PC Wi‑Fi IP로(예: http://192.168.x.x:8787). '
            '10.0.2.2·127.0.0.1은 폰에서 PC BFF로 붙지 않습니다. '
            '에뮬레이터만 http://10.0.2.2:포트. '
            'PC에서 BFF 실행·같은 Wi‑Fi·Windows 방화벽·http는 디버그 빌드 확인.';
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

/// Dio 기반 NHIS/BFF 호출이 PC·포트 미연결 등으로 끊긴 경우.
bool nhisFailureLooksLikeUnreachableHost(AppFailure failure) {
  final c = failure.cause;
  if (c is DioException) {
    switch (c.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        break;
    }
  }
  if (c is SocketException) return true;
  return false;
}

/// `package:http` BFF 플로우 등 [catch (e)] 에서 동일 판별.
bool link26ErrorLooksLikeUnreachableHost(Object e) {
  if (e is TimeoutException) return true;
  if (e is SocketException) return true;
  if (e is HttpException) return true;
  final s = e.toString().toLowerCase();
  return s.contains('clientexception') ||
      s.contains('connection refused') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection timed out') ||
      s.contains('timed out') ||
      s.contains('errno = 65') ||
      s.contains('errno = 61') ||
      s.contains('no route to host');
}
