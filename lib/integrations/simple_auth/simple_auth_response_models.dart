class SimpleAuthStartResponse {
  const SimpleAuthStartResponse({required this.authUrl});

  final String authUrl;

  factory SimpleAuthStartResponse.fromJson(Map<String, dynamic> json) {
    return SimpleAuthStartResponse(
      authUrl: json['authUrl'] as String? ?? '',
    );
  }
}
