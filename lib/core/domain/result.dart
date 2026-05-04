import 'failure.dart';

/// 성공/실패를 명시적으로 표현.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R fold<R>({required R Function(T data) onSuccess, required R Function(AppFailure e) onFailure}) {
    final self = this;
    if (self is Success<T>) return onSuccess(self.data);
    if (self is Failure<T>) return onFailure(self.error);
    throw StateError('Unknown Result');
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}
