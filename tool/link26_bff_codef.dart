// link26_bff CODEF 연동 — `dart run tool/link26_bff.dart` 에서 import.
//
// CODEF 요청 형식은 codef-io/codef-node 샘플과 동일:
// - OAuth: https://oauth.codef.io/oauth/token
// - 상품: POST baseUrl + path, Body = Uri.encodeComponent(jsonEncode(map))
// - 응답: URL 디코딩 후 JSON
//
// 상품 URL·파라미터는 https://developer.codef.io 에서 확인 (건강·복약 상품별 상이).

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 프로젝트 루트 환경을 읽습니다.
///
/// 1) `assets/env/dotenv` — Flutter 빌드 전 `sync_dotenv_asset.ps1` 가 루트 `.env` 를 복사한 파일.
/// 2) `.env` — 루트(덮어쓰기 우선).
///
/// 예전에는 BFF가 `.env` 만 봐서, 키를 `dotenv` 쪽에만 맞춰 둔 경우(또는 동기화만 한 경우)
/// e약은요·틸코 키가 "비어 있다"고 나왔습니다. 두 파일을 병합합니다.
/// `BFF_*` / `CODEF_*` / `NHIS_*` … 는 비어 있지 않은 [Platform.environment] 값이 마지막에 덮어씁니다.
Map<String, String> loadBffDotEnv() {
  final merged = <String, String>{};
  final root = _link26ProjectRoot();
  void mergeFile(String relativePath) {
    final f = File(p.join(root, relativePath));
    if (f.existsSync()) {
      merged.addAll(_parseDotEnv(f.readAsStringSync()));
    }
  }
  mergeFile(p.join('assets', 'env', 'dotenv'));
  mergeFile('.env');

  for (final e in Platform.environment.entries) {
    final k = e.key;
    if (!k.startsWith('BFF_') &&
        !k.startsWith('CODEF_') &&
        !k.startsWith('NHIS_') &&
        !k.startsWith('TILKO_') &&
        !k.startsWith('PUBLIC_DATA_') &&
        !k.startsWith('DATA_GO_KR_')) {
      continue;
    }
    final v = e.value.trim();
    if (v.isNotEmpty) merged[k] = v;
  }
  return merged;
}

/// `dart run tool/link26_bff.dart` 기준 상위 폴더, 또는 cwd 가 레포 루트일 때 그 경로.
String _link26ProjectRoot() {
  final scriptRoot = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..'),
  );
  final cwd = Directory.current.path;
  if (File(p.join(cwd, '.env')).existsSync() ||
      File(p.join(cwd, 'assets', 'env', 'dotenv')).existsSync()) {
    return cwd;
  }
  if (File(p.join(scriptRoot, '.env')).existsSync() ||
      File(p.join(scriptRoot, 'assets', 'env', 'dotenv')).existsSync()) {
    return scriptRoot;
  }
  return scriptRoot;
}

/// 공공데이터포털 `serviceKey`(e약은요 등). `.env` 에 이름이 여러 가지로 흔해 한 함수로 묶습니다.
String bffPublicDataServiceKey(Map<String, String> env) {
  const candidates = [
    'PUBLIC_DATA_SERVICE_KEY',
    'DATA_GO_KR_SERVICE_KEY',
    'NHIS_SERVICE_KEY',
  ];
  for (final k in candidates) {
    final v = (env[k] ?? '').trim();
    if (v.isNotEmpty) return v;
  }
  return '';
}

bool bffPublicDataConfigured(Map<String, String> env) =>
    bffPublicDataServiceKey(env).isNotEmpty;

Map<String, String> _parseDotEnv(String raw) {
  final out = <String, String>{};
  for (var line in LineSplitter.split(raw)) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var val = line.substring(eq + 1).trim();
    val = _stripQuotes(val);
    out[key] = val;
  }
  return out;
}

String _stripQuotes(String v) {
  if (v.length >= 2 &&
      ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'")))) {
    return v.substring(1, v.length - 1).trim();
  }
  return v;
}

bool _truthy(String? s) {
  final t = (s ?? '').trim().toLowerCase();
  return t == 'true' || t == '1' || t == 'yes';
}

/// link26_bff.dart 헬스 응답용.
bool bffEnvTruthy(String? s) => _truthy(s);

/// `/v1/medications` 에서 CODEF 상품 호출에 필요한 클라이언트 설정이 모두 있는지.
bool bffMedicationsCodefConfigured(Map<String, String> env) {
  final pathSet = (env['CODEF_MEDICATION_PATH'] ?? '').trim().isNotEmpty;
  final idSet = (env['CODEF_CLIENT_ID'] ?? '').trim().isNotEmpty;
  final secretSet = (env['CODEF_CLIENT_SECRET'] ?? '').trim().isNotEmpty;
  return bffEnvTruthy(env['BFF_USE_CODEF_FOR_MEDICATIONS']) &&
      pathSet &&
      idSet &&
      secretSet;
}

/// 쿼리 `connectedId` 우선, 없으면 `.env` 의 `CODEF_CONNECTED_ID`.
String bffResolvedConnectedId(
  Map<String, String> query,
  Map<String, String> env,
) {
  final fromQ = (query['connectedId'] ?? '').trim();
  if (fromQ.isNotEmpty) return fromQ;
  return (env['CODEF_CONNECTED_ID'] ?? '').trim();
}

/// `true`이면 connectedId 없이도 CODEF 호출 시도 (상품 스펙상 필요 없을 때만).
bool bffAllowCodefWithoutConnectedId(Map<String, String> env) =>
    bffEnvTruthy(env['BFF_ALLOW_CODEF_WITHOUT_CONNECTED_ID']);

class CodefTokenCache {
  String? _token;
  DateTime? _expiresAt;

  Future<String> token({
    required String clientId,
    required String clientSecret,
  }) async {
    final now = DateTime.now();
    if (_token != null &&
        _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(const Duration(minutes: 2)))) {
      return _token!;
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('https://oauth.codef.io/oauth/token');
      final req = await client.postUrl(uri);
      final basic = base64Encode(utf8.encode('$clientId:$clientSecret'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Basic $basic');
      req.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      req.write('grant_type=client_credentials&scope=read');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        throw StateError('OAuth ${res.statusCode}: $body');
      }
      final map = jsonDecode(body) as Map<String, dynamic>;
      final access = map['access_token'] as String?;
      if (access == null || access.isEmpty) {
        throw StateError('OAuth 응답에 access_token 없음');
      }
      final expSec = (map['expires_in'] as num?)?.toInt() ?? 604800;
      _token = access;
      _expiresAt = now.add(Duration(seconds: expSec));
      return access;
    } finally {
      client.close(force: true);
    }
  }
}

final _codefToken = CodefTokenCache();

/// CODEF 상품 POST (codef-node httpSender 와 동일).
Future<String> codefProductRaw({
  required String baseUrl,
  required String productPath,
  required String bearer,
  required Map<String, dynamic> body,
}) async {
  final uri = Uri.parse(baseUrl + productPath);
  final client = HttpClient();
  try {
    final req = await client.postUrl(uri);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    final encoded = Uri.encodeQueryComponent(jsonEncode(body));
    req.write(encoded);
    final res = await req.close();
    final raw = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw StateError('CODEF HTTP ${res.statusCode}: $raw');
    }
    try {
      return Uri.decodeQueryComponent(raw);
    } catch (_) {
      return raw;
    }
  } finally {
    client.close(force: true);
  }
}

/// `/v1/medications` 용: `.env` 에 `BFF_USE_CODEF_FOR_MEDICATIONS=true` 이고
/// `CODEF_CLIENT_*` + `CODEF_MEDICATION_PATH` 가 있을 때만 CODEF 호출.
/// 미설정·오류 시 null → 스텁 응답.
Future<Map<String, dynamic>?> fetchMedicationsFromCodef({
  required Map<String, String> env,
  required String phoneDigits,
  String? connectedIdOverride,
  String displayName = '',
  String gender = '',
}) async {
  if (!_truthy(env['BFF_USE_CODEF_FOR_MEDICATIONS'])) return null;

  final path = (env['CODEF_MEDICATION_PATH'] ?? '').trim();
  final id = (env['CODEF_CLIENT_ID'] ?? '').trim();
  final secret = (env['CODEF_CLIENT_SECRET'] ?? '').trim();
  if (id.isEmpty || secret.isEmpty || path.isEmpty) return null;

  final base = (env['CODEF_BASE_URL'] ?? 'https://development.codef.io').trim();

  final connectedId =
      (connectedIdOverride ?? env['CODEF_CONNECTED_ID'] ?? '').trim();
  final org = (env['CODEF_HW_ORGANIZATION'] ?? env['CODEF_ORGANIZATION'] ?? '')
      .trim();

  final body = <String, dynamic>{};
  if (connectedId.isNotEmpty) body['connectedId'] = connectedId;
  if (org.isNotEmpty) body['organization'] = org;
  if (phoneDigits.isNotEmpty) {
    body['phoneNo'] = phoneDigits;
    body['id'] = phoneDigits;
  }
  final dn = displayName.trim();
  if (dn.isNotEmpty) {
    body['displayName'] = dn;
    body['userName'] = dn;
    body['name'] = dn;
  }
  final gen = gender.trim();
  if (gen.isNotEmpty) body['gender'] = gen;

  final extraJson = (env['CODEF_REQUEST_JSON'] ?? '').trim();
  if (extraJson.isNotEmpty) {
    try {
      final decoded = jsonDecode(extraJson);
      if (decoded is Map) {
        body.addAll(_stringKeyMap(decoded));
      }
    } catch (_) {
      stderr.writeln('CODEF_REQUEST_JSON 파싱 실패 — 무시');
    }
  }

  try {
    if (!path.startsWith('/')) {
      throw StateError('CODEF_MEDICATION_PATH 는 / 로 시작해야 합니다.');
    }
    final pathLower = path.toLowerCase();
    if (pathLower.contains('connectedid-list') ||
        pathLower.contains('/v1/account/')) {
      throw StateError(
        'CODEF_MEDICATION_PATH 가 계정/연동 목록 API($path)를 가리킵니다. '
        'developer.codef.io 에서 「국민건강보험공단 건보진료정보」등 복약·진료 상품의 '
        '요청 URL 경로를 그대로 넣어야 합니다. connectedId-list 는 약 목록이 아닙니다.',
      );
    }
    final bearer = await _codefToken.token(clientId: id, clientSecret: secret);
    final decoded = await codefProductRaw(
      baseUrl: base,
      productPath: path,
      bearer: bearer,
      body: body,
    );
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    final items = bffMapCodefRootToMedicationItems(map);
    final result = map['result'];
    String? code;
    String? message;
    if (result is Map) {
      code = '${result['code'] ?? ''}';
      message = '${result['message'] ?? ''}';
    }

    return {
      'items': items,
      'meta': {
        'source': 'codef',
        'phone': phoneDigits,
        'connectedId': connectedId.isEmpty ? null : connectedId,
        'productPath': path,
        'codefResultCode': code,
        'codefResultMessage': message,
      },
    };
  } catch (e, st) {
    stderr.writeln('CODEF medications 오류: $e\n$st');
    return {
      'items': <Map<String, dynamic>>[],
      'meta': {
        'source': 'codef_error',
        'phone': phoneDigits,
        'error': '$e',
      },
    };
  }
}

/// CODEF 건강iN/건보 진료·투약 JSON 루트에서 앱/BFF 공통 약 행 목록을 뽑습니다.
List<Map<String, dynamic>> bffMapCodefRootToMedicationItems(Map<String, dynamic> root) {
  final rows = _extractDataRows(root['data']);
  final out = <Map<String, dynamic>>[];
  for (final r in rows) {
    final name = _firstNonEmpty(r, const [
      'name',
      'drugName',
      'medicineName',
      'itemName',
      'resDrugName',
      'resDrugNm',
      'drugNm',
      'mediNm',
      'mediName',
      'drugNameKr',
      '약품명',
      '품명',
    ]);
    if (name.isEmpty) continue;
    out.add({
      'name': name,
      'dose': _firstNonEmpty(r, const ['dose', 'dosage', 'resDosage', '일투']),
      'frequency': _firstNonEmpty(r, const ['frequency', 'resFrequency', '복약']),
      'time': _firstNonEmpty(r, const ['time', 'resTime', '투약시각']),
    });
  }
  return out;
}

Map<String, dynamic> _stringKeyMap(Map raw) {
  final out = <String, dynamic>{};
  for (final e in raw.entries) {
    out['${e.key}'] = e.value;
  }
  return out;
}

List<Map<String, dynamic>> _extractDataRows(dynamic data) {
  if (data == null) return [];
  if (data is String) {
    final s = data.trim();
    if (s.isEmpty) return [];
    try {
      return _extractDataRows(jsonDecode(s));
    } catch (_) {
      return [];
    }
  }
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => _stringKeyMap(e))
        .toList();
  }
  if (data is Map) {
    final m = _stringKeyMap(data);
    for (final key in [
      'list',
      'resList',
      'drugList',
      'medicationList',
      'medicineList',
      'items',
      'resTreatmentList',
      'treatmentList',
      'prescriptionList',
      'medicationTakingList',
      'takingList',
    ]) {
      final v = m[key];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => _stringKeyMap(e))
            .toList();
      }
    }
  }
  return [];
}

String _firstNonEmpty(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = '$v'.trim();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return '';
}

/// BFF에서 CODEF Bearer 재사용 (캐시).
Future<String> bffCodefBearer(Map<String, String> env) async {
  final id = (env['CODEF_CLIENT_ID'] ?? '').trim();
  final secret = (env['CODEF_CLIENT_SECRET'] ?? '').trim();
  if (id.isEmpty || secret.isEmpty) {
    throw StateError('CODEF_CLIENT_ID/SECRET 없음');
  }
  return _codefToken.token(clientId: id, clientSecret: secret);
}

/// 헬스용: 토큰 발급만 검증 (상품 호출 없음).
Future<Map<String, dynamic>> codefHealthProbe(Map<String, String> env) async {
  final id = (env['CODEF_CLIENT_ID'] ?? '').trim();
  final secret = (env['CODEF_CLIENT_SECRET'] ?? '').trim();
  if (id.isEmpty || secret.isEmpty) {
    return {'configured': false, 'token': 'skipped', 'detail': 'no client id/secret'};
  }
  try {
    await _codefToken.token(clientId: id, clientSecret: secret);
    return {'configured': true, 'token': 'ok'};
  } catch (e) {
    return {'configured': true, 'token': 'error', 'detail': '$e'};
  }
}
