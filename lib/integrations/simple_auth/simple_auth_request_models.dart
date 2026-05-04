class SimpleAuthStartRequest {
  const SimpleAuthStartRequest({required this.redirectUri});

  final String redirectUri;

  Map<String, dynamic> toJson() => {'redirectUri': redirectUri};
}
