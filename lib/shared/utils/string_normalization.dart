/// 검색·비교용 문자열 정규화(공백 축소, 앞뒤 trim).
String normalizeForLookup(String input) {
  return input.trim().replaceAll(RegExp(r'\s+'), ' ');
}
