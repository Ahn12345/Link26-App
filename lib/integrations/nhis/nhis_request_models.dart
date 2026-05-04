class NhisTokenRequest {
  const NhisTokenRequest({required this.code});

  final String code;

  Map<String, dynamic> toJson() => {'code': code};
}
