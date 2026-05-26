/// Gemini REST 오류 — SDK의 「모델 없음」 메시지보다 원본 HTTP 본문을 우선합니다.
final class GeminiHttpException implements Exception {
  GeminiHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'GeminiHttpException($statusCode): $body';
}
