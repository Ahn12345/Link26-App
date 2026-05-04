extension DateTimeX on DateTime {
  DateTime get startOfDayLocal {
    final l = toLocal();
    return DateTime(l.year, l.month, l.day);
  }
}
