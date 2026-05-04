class AppError {
  const AppError(this.message, {this.code});

  final String message;
  final String? code;
}
