/// BFF `POST /v1/flow/tilko-hira-medications`(구 `tilko-codef-treatment`) 응답·
/// 레거시 CODEF JSON에서 `connectedId` 추출.
/// 앱 저장·BFF echo·테스트가 같은 규칙을 씁니다.
String? parseConnectedIdFromBffFlowResponse(Map<String, dynamic> res) {
  String? pick(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  final top = pick(res['connectedId']) ?? pick(res['connected_id']);
  if (top != null) return top;

  final meta = res['meta'];
  if (meta is Map) {
    final mm = Map<String, dynamic>.from(
      meta.map((k, v) => MapEntry('$k', v)),
    );
    final m = pick(mm['connectedId']) ?? pick(mm['connected_id']);
    if (m != null) return m;
  }

  final codef = res['codef'];
  if (codef is Map) {
    return parseConnectedIdFromCodefRootMap(
      Map<String, dynamic>.from(codef.map((k, v) => MapEntry('$k', v))),
    );
  }
  return null;
}

/// CODEF API JSON 루트(또는 `codef` 객체)에서 `connectedId` 추출.
String? parseConnectedIdFromCodefRootMap(Map<String, dynamic> root) {
  String? pick(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  final m = Map<String, dynamic>.from(root);
  var d = pick(m['connectedId']) ?? pick(m['connected_id']);
  if (d != null) return d;

  final data = m['data'];
  if (data is Map) {
    final dm = Map<String, dynamic>.from(data.map((k, v) => MapEntry('$k', v)));
    d = pick(dm['connectedId']) ?? pick(dm['connected_id']);
    if (d != null) return d;
    final inner = dm['res'];
    if (inner is Map) {
      final im = Map<String, dynamic>.from(
        inner.map((k, v) => MapEntry('$k', v)),
      );
      d = pick(im['connectedId']) ?? pick(im['connected_id']);
      if (d != null) return d;
    }
  }
  return null;
}
