class MedicineSearchRequest {
  const MedicineSearchRequest({required this.query});

  final String query;

  Map<String, dynamic> toJson() => {'query': query};
}
