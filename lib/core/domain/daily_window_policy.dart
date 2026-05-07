/// Defines a daily window that resets at [resetHour].
class DailyWindowPolicy {
  const DailyWindowPolicy({this.resetHour = 4});

  final int resetHour;

  DateTime windowStartFor(DateTime instant) {
    final local = instant.toLocal();
    final candidate = DateTime(local.year, local.month, local.day, resetHour);
    if (local.isBefore(candidate)) {
      return candidate.subtract(const Duration(days: 1));
    }
    return candidate;
  }

  bool isSameWindow(DateTime a, DateTime b) {
    return windowStartFor(a) == windowStartFor(b);
  }
}