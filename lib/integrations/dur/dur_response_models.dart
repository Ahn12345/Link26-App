class DurCheckResponse {
  const DurCheckResponse({required this.level, this.message});

  final String level;
  final String? message;

  factory DurCheckResponse.fromJson(Map<String, dynamic> json) {
    return DurCheckResponse(
      level: json['level'] as String? ?? 'unknown',
      message: json['message'] as String?,
    );
  }
}
