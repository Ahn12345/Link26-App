/// 일일 복용·AI 집계 기준: 매일 [resetHour]시에 “하루”가 바뀐다고 가정한다.
/// 예: 04:00 기준이면 03:59까지는 전날 창, 04:00부터 오늘 창.
class DailyWindowPolicy {
  const DailyWindowPolicy({this.resetHour = 4});

  /// 0–23, 기본 04시 (요구사항).
  final int resetHour;

  /// [instant]이 속한 “복용 일일 창”의 시작 시각(로컬).
  DateTime windowStartFor(DateTime instant) {
    final local = instant.toLocal();
    final candidate = DateTime(
      local.year,
      local.month,
      local.day,
      resetHour,
    );
    if (local.isBefore(candidate)) {
      return candidate.subtract(const Duration(days: 1));
    }
    return candidate;
  }

  /// 같은 일일 창인지.
  bool isSameWindow(DateTime a, DateTime b) {
    return windowStartFor(a) == windowStartFor(b);
  }
}
