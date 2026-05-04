import 'package:http/http.dart' as http;

import '../domain/failure.dart';

AppFailure mapHttpException(Object e, [StackTrace? st]) {
  if (e is http.ClientException) {
    return AppFailure('네트워크 오류', cause: e);
  }
  return AppFailure('알 수 없는 오류', cause: e);
}

AppFailure mapStatusCode(int code, String body) {
  return AppFailure('HTTP $code', code: '$code', cause: body);
}
