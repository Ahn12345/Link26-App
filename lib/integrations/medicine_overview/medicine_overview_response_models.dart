class MedicineSummary {
  const MedicineSummary({
    required this.name,
    required this.code,
    this.caution,
  });

  final String name;
  final String code;
  final String? caution;

  factory MedicineSummary.fromJson(Map<String, dynamic> json) {
    return MedicineSummary(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      caution: json['caution'] as String?,
    );
  }
}
