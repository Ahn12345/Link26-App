bool isBlank(String? s) => s == null || s.trim().isEmpty;

String nullToEmpty(String? s) => s ?? '';

String truncate(String s, int maxLen) {
  if (s.length <= maxLen) return s;
  return '${s.substring(0, maxLen)}…';
}
