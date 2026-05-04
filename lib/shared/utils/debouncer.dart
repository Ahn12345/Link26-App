import 'dart:async';

/// 검색·입력 등 연속 이벤트를 묶어 마지막 콜백만 실행합니다.
final class Debouncer {
  Debouncer({required this.duration});

  final Duration duration;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
