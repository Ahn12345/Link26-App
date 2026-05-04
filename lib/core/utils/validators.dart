String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return '이메일을 입력하세요.';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim());
  if (!ok) return '이메일 형식이 올바르지 않습니다.';
  return null;
}

String? validatePassword(String? value, {int minLen = 8}) {
  if (value == null || value.isEmpty) return '비밀번호를 입력하세요.';
  if (value.length < minLen) return '비밀번호는 $minLen자 이상이어야 합니다.';
  return null;
}
