/// 앱 전역 예외/실패 표현.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'AppFailure($code): $message';
}
