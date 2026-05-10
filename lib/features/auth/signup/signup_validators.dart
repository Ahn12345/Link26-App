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
}
