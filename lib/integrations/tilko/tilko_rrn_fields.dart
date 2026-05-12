/// 틸코 간편인증 요청용 — 주민등록번호에서 생년월일(YYYYMMDD)만 계산합니다.
abstract final class TilkoRrnFields {
  static String? birthYmdFromRrn(String thirteenDigits) {
    final d = thirteenDigits.replaceAll(RegExp(r'\D'), '');
    if (d.length != 13) return null;
    final yy = int.tryParse(d.substring(0, 2));
    if (yy == null) return null;
    final mm = d.substring(2, 4);
    final dd = d.substring(4, 6);
    final g = int.tryParse(d[6]);
    if (g == null) return null;
    final int century;
    if (g == 1 || g == 2 || g == 5 || g == 6) {
      century = 1900;
    } else if (g == 3 || g == 4 || g == 7 || g == 8) {
      century = 2000;
    } else if (g == 9 || g == 0) {
      century = 1800;
    } else {
      return null;
    }
    return '${century + yy}$mm$dd';
  }
}
