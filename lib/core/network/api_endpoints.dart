import '../constants/api_keys.dart';

/// 통합 엔드포인트 조립 (baseUrl 비어 있으면 호출 시 실패 처리).
Uri buildUri(String path, {Map<String, String>? query, required String base}) {
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final p = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$root$p').replace(queryParameters: query);
}

Uri nhisUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.nhisBaseUrl);

Uri durUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.durBaseUrl);

Uri medicineOverviewUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.medicineOverviewBaseUrl);

Uri simpleAuthUri(String path, {Map<String, String>? query}) =>
    buildUri(path, query: query, base: ApiConfig.simpleAuthBaseUrl);
