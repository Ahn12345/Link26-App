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
            'Wi‑Fi·데이터를 확인하고, 디버그에서는 PC BFF 주소(NHIS_BASE_URL)와 '
            '같은 네트워크인지 확인하세요.';
      case DioExceptionType.badCertificate:
        return 'SSL 인증서 오류 — https 주소·기업용 인증서를 확인하세요.';
      case DioExceptionType.badResponse:
        final code = c.response?.statusCode;
        return code != null
            ? '서버 응답 $code — 경로·JSON 스펙이 BFF와 맞는지 확인하세요.'
            : '서버 오류 응답 — BFF 로그를 확인하세요.';
      default:
        final m = c.message?.trim();
        if (m != null && m.isNotEmpty) {
          return 'GET/연동 오류: $m';
        }
        break;
    }
  }
  final msg = failure.message.trim();
  if (msg.contains(': null') || msg.endsWith('null')) {
    return '서버에 연결할 수 없습니다. PC에서 BFF(8787) 실행·USB면 adb reverse, '
        'Wi‑Fi면 NHIS_BASE_URL IP를 확인하세요.';
  }
  return failure.message;
}

/// Dio 기반 NHIS/BFF 호출이 PC·포트 미연결 등으로 끊긴 경우.
bool nhisFailureLooksLikeUnreachableHost(AppFailure failure) {
  final c = failure.cause;
  if (c is DioException) {
    return dioExceptionLooksUnreachable(c);
  }
  if (c is SocketException) return true;
  return false;
}

/// [DioException] 만으로 연결 계열 실패인지 판별합니다.
bool dioExceptionLooksUnreachable(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      return false;
  }
}

/// `package:http` BFF 플로우 등 [catch (e)] 에서 연결 실패 판별.
/// [TimeoutException] 은 호출부에서 「응답 시간 초과」로 따로 처리합니다.
bool link26ErrorLooksLikeUnreachableHost(Object e) {
  if (e is TimeoutException) return false;
  if (e is SocketException) return true;
  if (e is HttpException) return true;
  final s = e.toString().toLowerCase();
  return s.contains('clientexception') ||
      s.contains('connection refused') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection timed out') ||
      s.contains('errno = 65') ||
      s.contains('errno = 61') ||
      s.contains('no route to host');
}
