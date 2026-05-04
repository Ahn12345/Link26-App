class NhisUserProfile {
  const NhisUserProfile({required this.name, this.insuranceId});

  final String name;
  final String? insuranceId;

  factory NhisUserProfile.fromJson(Map<String, dynamic> json) {
    return NhisUserProfile(
      name: json['name'] as String? ?? '',
      insuranceId: json['insuranceId'] as String?,
    );
  }
}
