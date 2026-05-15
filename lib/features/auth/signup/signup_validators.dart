/// 회원가입 입력 검증 (로컬).
abstract final class SignupValidators {
  SignupValidators._();

  static String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// 국내 휴대전화 기준 숫자 10~11자리.
  static bool isPhoneKr(String raw) {
    final d = digitsOnly(raw);
    return d.length >= 10 && d.length <= 11;
  }

  static bool isRrn13Digits(String raw) {
    final d = digitsOnly(raw);
    return d.length == 13;
  }

  /// 틸코 `BirthDate` — YYYYMMDD 8자리·유효한 날짜.
  static bool isBirthYmd8(String raw) {
    final d = digitsOnly(raw);
    if (d.length != 8) return false;
    final y = int.tryParse(d.substring(0, 4));
    final m = int.tryParse(d.substring(4, 6));
    final day = int.tryParse(d.substring(6, 8));
    if (y == null || m == null || day == null) return false;
    if (m < 1 || m > 12 || day < 1 || day > 31) return false;
    try {
      final dt = DateTime(y, m, day);
      return dt.year == y && dt.month == m && dt.day == day;
    } catch (_) {
      return false;
    }
  }

  /// 주민번호 앞 6자리·성별코드와 생년월일(YYYYMMDD) 일치 여부.
  static bool birthYmdMatchesRrn(String birthYmd, String rrnRaw) {
    final birth = digitsOnly(birthYmd);
    final rrn = digitsOnly(rrnRaw);
    if (birth.length != 8 || rrn.length != 13) return false;
    final fromRrn = birth.substring(2);
    return rrn.startsWith(fromRrn);
  }
}
