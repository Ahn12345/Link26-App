class DurCheckRequest {
  const DurCheckRequest({required this.drugCodes});

  final List<String> drugCodes;

  Map<String, dynamic> toJson() => {'drugCodes': drugCodes};
}
