/// 딥링크/웹뷰 콜백에서 authorization code 추출 (플랫폼별 구현은 추후).
String? extractAuthCodeFromCallbackUri(Uri uri) {
  return uri.queryParameters['code'];
}
