import 'dur_response_models.dart';

/// API 응답과 로컬 CSV 기반 결과를 합친다 (추후 구현 확장).
DurCheckResponse mergeDurResults(DurCheckResponse api, DurCheckResponse? local) {
  if (local == null) return api;
  const rank = {'red': 3, 'yellow': 2, 'green': 1, 'unknown': 0};
  final a = rank[api.level] ?? 0;
  final b = rank[local.level] ?? 0;
  if (b > a) return local;
  return api;
}
