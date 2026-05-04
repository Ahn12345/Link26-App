/// 매일 [resetHour]에 일일 창이 바뀐다고 가정.
DateTime dailyWindowStart(DateTime instant, {int resetHour = 4}) {
  final local = instant.toLocal();
  final boundary = DateTime(local.year, local.month, local.day, resetHour);
  if (local.isBefore(boundary)) {
    return boundary.subtract(const Duration(days: 1));
  }
  return boundary;
}
