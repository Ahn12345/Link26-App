/// 카카오 functional 샘플용 간단 약 모델 (`Medication` / `link_models` 과 별개).
class Medicine {
  final String name;
  final String dose;
  final String frequency;
  final String time;

  const Medicine({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.time,
  });
}
