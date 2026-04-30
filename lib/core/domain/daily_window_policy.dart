/// ?¼ì¼ ë³µìš©Â·AI ì§‘ê³„ ê¸°ì?: ë§¤ì¼ [resetHour]?œì— ?œí•˜ë£¨â€ê? ë°”ë€ë‹¤ê³?ê°€?•í•œ??
/// ?? 04:00 ê¸°ì??´ë©´ 03:59ê¹Œì????„ë‚  ì°? 04:00ë¶€???¤ëŠ˜ ì°?
class DailyWindowPolicy {
  const DailyWindowPolicy({this.resetHour = 4});

  /// 0??3, ê¸°ë³¸ 04??(?”êµ¬?¬í•­).
  final int resetHour;

  /// [instant]???í•œ ?œë³µ???¼ì¼ ì°½â€ì˜ ?œì‘ ?œê°(ë¡œì»¬).
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

  /// ê°™ì? ?¼ì¼ ì°½ì¸ì§€.
  bool isSameWindow(DateTime a, DateTime b) {
    return windowStartFor(a) == windowStartFor(b);
  }
}
