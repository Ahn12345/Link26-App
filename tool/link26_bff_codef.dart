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

import 'package:link26_app/core/services/codef_flow_connected_id_parse.dart';
import 'package:link26_app/integrations/codef/codef_medication_mapper.dart';
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

/// `CODEF_MEDICATION_PATH` 우선, 비어 있으면 틸코·건보 플로우와 동일한
/// `CODEF_NHIS_TREATMENT_PATH` 를 씁니다(같은 건보 진료·투약 상품 URL인 경우).
String bffResolvedMedicationProductPath(Map<String, String> env) {
  final a = (env['CODEF_MEDICATION_PATH'] ?? '').trim();
  if (a.isNotEmpty) return a;
  return (env['CODEF_NHIS_TREATMENT_PATH'] ?? '').trim();
}

/// `/v1/medications` 에서 CODEF 상품 호출에 필요한 클라이언트 설정이 모두 있는지.
bool bffMedicationsCodefConfigured(Map<String, String> env) {
  final path = bffResolvedMedicationProductPath(env);
  final idSet = (env['CODEF_CLIENT_ID'] ?? '').trim().isNotEmpty;
  final secretSet = (env['CODEF_CLIENT_SECRET'] ?? '').trim().isNotEmpty;
  return bffEnvTruthy(env['BFF_USE_CODEF_FOR_MEDICATIONS']) &&
      path.isNotEmpty &&
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

/// [baseUrl] 끝·[productPath] 앞 슬래시를 정리해 `//v1/...` 로 인한 CODEF 404 를 방지합니다.
Uri codefJoinedProductUri(String baseUrl, String productPath) {
  var b = baseUrl.trim();
  while (b.endsWith('/')) {
    b = b.substring(0, b.length - 1);
  }
  var p = productPath.trim();
  if (!p.startsWith('/')) p = '/$p';
  return Uri.parse('$b$p');
}

/// BFF 502 JSON `hint_ko`·스낵바용 — CODEF 상품 URL 404·CF-00404.
String? bffCodefFailureHintKo(Object? e) {
  if (e == null) return null;
  final s = e.toString();
  if (s.contains('CF-00404') ||
      s.contains('CODEF HTTP 404') ||
      s.contains('"code":"CF-00404"') ||
      s.contains('NOT_FOUND 404')) {
    return 'CODEF에서 상품 주소를 찾지 못했습니다(CF-00404). '
        'BFF .env의 CODEF_BASE_URL이 키 종류와 맞는지(개발: https://development.codef.io, '
        '운영: https://api.codef.io, 샌드박스: https://sandbox.codef.io) 확인하고, '
        'CODEF_NHIS_TREATMENT_PATH(또는 CODEF_MEDICATION_PATH)가 developer.codef.io '
        '해당 상품 문서의 «요청 URL» 경로와 동일한지 확인하세요. '
        'codef.io 콘솔에서 해당 공공 상품 이용 권한이 있는지도 확인하세요. '
        '데모·테스트용 클라이언트면 운영 대신 sandbox.codef.io 조합이 필요할 수 있습니다.';
  }
  if (s.contains('CF-00003') || s.contains('"code":"CF-00003"')) {
    return 'CODEF에서 해당 상품 구독·권한을 찾지 못했습니다(CF-00003). '
        'codef.io 콘솔에서 건보 진료·투약(nhis-insurance-treatment-information) '
        '상품 사용 권한이 있는지 확인하고, CODEF_BASE_URL·CODEF_NHIS_TREATMENT_PATH가 '
        'developer.codef.io 문서의 요청 URL·키 유형(개발·운영·샌드박스)과 일치하는지 확인하세요. '
        '문서상 필수인 경우 CODEF_HW_ORGANIZATION·connectedId를 .env 또는 codef_payload에 넣어 주세요.';
  }
  return null;
}

/// HTTP 200 본문의 `result.code` 가 비정상일 때 앱 `hint_ko` 용.
String? bffCodefNhisTreatResultHintKo(String? code, String? message) {
  final c = (code ?? '').trim();
  if (c.isEmpty || c == 'CF-00000') return null;
  if (c == 'CF-00003') {
    return 'CODEF에서 해당 상품 구독·권한을 찾지 못했거나(CF-00003), '
        '요청 본문이 상품 스펙과 맞지 않을 때도 같은 코드가 날 수 있습니다. '
        'codef.io 콘솔에서 「국민건강보험 진료·투약」상품 이용 권한을 확인하고, '
        'BFF가 넣는 organization(기본 0002)·loginType·loginTypeLevel·identity·_tilkoSimpleAuth 를 '
        'developer.codef.io 문서와 맞추세요. '
        '(틸코 API KEY는 심평원 간편인증용이며, CF-00003은 CODEF 상품·호스트 문제인 경우가 많습니다.)';
  }
  final m = (message ?? '').trim();
  if (m.isNotEmpty) {
    return 'CODEF 상품 응답: $c — $m. developer.codef.io 해당 상품의 요청 필드·구독을 확인하세요.';
  }
  return 'CODEF 상품 응답 코드가 정상이 아닙니다($c). developer.codef.io 문서·콘솔 구독을 확인하세요.';
}

/// CODEF 공공 건보 샘플(이지코드에프 README) 기준 국민건강보험공단 기관코드.
const String codefNhisOrganizationDefault = '0002';

/// 생년월일 등에서 숫자만 남겨 앞 8자리 `yyyyMMdd` (CODEF `identity` 등).
String? codefNormIdentityYmd8(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length < 8) return null;
  return d.substring(0, 8);
}

/// 틸코 `PrivateAuthType` → CODEF 간편인증 `loginTypeLevel` (`loginType` 이 `5` 일 때).
/// 샘플: 1=카카오, 2=페이코, 3=삼성패스, 4=KB, 5=통신사 PASS, 6=네이버, 7=신한, 8=토스.
String codefLoginTypeLevelFromPrivateAuth(String privateAuthTypeUpper) {
  switch (privateAuthTypeUpper.trim().toUpperCase()) {
    case 'KAKAO':
      return '1';
    case 'PAYCO':
      return '2';
    case 'SAMSUNG':
    case 'SAMSUNGPASS':
      return '3';
    case 'KB':
    case 'KBMOBILE':
      return '4';
    case 'PASS':
    case 'TELCO':
    case 'PHONE':
      return '5';
    case 'NAVER':
      return '6';
    case 'SHINHAN':
      return '7';
    case 'TOSS':
      return '8';
    default:
      return '1';
  }
}

/// 토큰·URL 검증용 최소 본문(샘플 필드). 실제 본인 조회는 틸코 플로우·실명 값 필요.
Map<String, dynamic> codefNhisTreatmentProbeBody(Map<String, String> env) {
  final orgEnv =
      (env['CODEF_HW_ORGANIZATION'] ?? env['CODEF_ORGANIZATION'] ?? '').trim();
  final org =
      orgEnv.isNotEmpty ? orgEnv : codefNhisOrganizationDefault;
  final phone = (env['CODEF_VERIFY_PLACEHOLDER_PHONE'] ?? '01000000000')
      .replaceAll(RegExp(r'\D'), '');
  final phoneOk = phone.length >= 10 ? phone : '01000000000';
  final ident = codefNormIdentityYmd8(
        env['CODEF_VERIFY_PLACEHOLDER_IDENTITY'] ?? '19900101',
      ) ??
      '19900101';
  final body = <String, dynamic>{
    'organization': org,
    'loginType': (env['CODEF_NHIS_LOGINTYPE'] ?? '5').trim(),
    'loginTypeLevel': (env['CODEF_NHIS_LOGINTYPE_LEVEL'] ?? '1').trim(),
    'userName': (env['CODEF_VERIFY_PLACEHOLDER_NAME'] ?? '홍길동').trim(),
    'phoneNo': phoneOk,
    'identity': ident,
  };
  final cid = (env['CODEF_CONNECTED_ID'] ?? '').trim();
  if (cid.isNotEmpty) {
    body['connectedId'] = cid;
  }
  return body;
}

/// 틸코→CODEF 건보 진료·투약 POST 본문에 공통 필드를 채웁니다.
/// [codefExtra]는 앱 `codef_payload`, [tilkoMap]은 틸코 요청 입력, [tilkoRes]는 `_tilkoSimpleAuth` 로 실립니다.
Map<String, dynamic> mergeCodefNhisTilkoTreatmentBody({
  required Map<String, String> env,
  required Map<String, dynamic> codefExtra,
  required Map<String, dynamic> tilkoMap,
  required Map<String, dynamic> tilkoRes,
}) {
  final merged = Map<String, dynamic>.from(codefExtra)
    ..['_tilkoSimpleAuth'] = tilkoRes;

  final orgEnv =
      (env['CODEF_HW_ORGANIZATION'] ?? env['CODEF_ORGANIZATION'] ?? '').trim();
  merged.putIfAbsent(
    'organization',
    () => orgEnv.isNotEmpty ? orgEnv : codefNhisOrganizationDefault,
  );

  /// 틸코 간편인증 결과가 있을 때 루트 `loginType` 등과 이중 지정되면 CODEF가 CF-00003 을 줄 수 있어
  /// 기본은 생략합니다. 문서상 필수면 `CODEF_NHIS_INCLUDE_LOGINTYPE_WITH_TILKO=true`.
  final tilkoAuthPresent = tilkoRes.isNotEmpty;
  final forceLoginType =
      _truthy(env['CODEF_NHIS_INCLUDE_LOGINTYPE_WITH_TILKO']);
  if (forceLoginType || !tilkoAuthPresent) {
    merged.putIfAbsent(
      'loginType',
      () => (env['CODEF_NHIS_LOGINTYPE'] ?? '5').trim(),
    );

    final pat =
        '${tilkoMap['PrivateAuthType'] ?? tilkoMap['privateAuthType'] ?? ''}'
            .trim()
            .toUpperCase();
    final levelEnv = (env['CODEF_NHIS_LOGINTYPE_LEVEL'] ?? '').trim();
    merged.putIfAbsent(
      'loginTypeLevel',
      () => levelEnv.isNotEmpty
          ? levelEnv
          : codefLoginTypeLevelFromPrivateAuth(pat),
    );
  }

  final envCid = (env['CODEF_CONNECTED_ID'] ?? '').trim();
  if (envCid.isNotEmpty) {
    merged.putIfAbsent('connectedId', () => envCid);
  }

  String digits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  final phoneRaw =
      '${tilkoMap['UserCellphoneNumber'] ?? tilkoMap['userCellphoneNumber'] ?? ''}';
  final phone = digits(phoneRaw);
  if (phone.length >= 10) {
    merged.putIfAbsent('phoneNo', () => phone);
    merged.putIfAbsent('id', () => phone);
  }

  final uname =
      '${tilkoMap['UserName'] ?? tilkoMap['userName'] ?? ''}'.trim();
  if (uname.isNotEmpty) {
    merged.putIfAbsent('userName', () => uname);
    merged.putIfAbsent('name', () => uname);
    merged.putIfAbsent('displayName', () => uname);
  }

  final birthRaw =
      '${tilkoMap['BirthDate'] ?? tilkoMap['birthDate'] ?? ''}'.trim();
  final ident = codefNormIdentityYmd8(birthRaw);
  if (ident != null) {
    merged.putIfAbsent('identity', () => ident);
    merged.putIfAbsent('birthYmd', () => ident);
  }
  if (birthRaw.isNotEmpty) {
    merged.putIfAbsent('birthDate', () => birthRaw);
    if (ident == null) {
      merged.putIfAbsent('birthYmd', () => birthRaw);
    }
  }

  final extraJson = (env['CODEF_REQUEST_JSON'] ?? '').trim();
  if (extraJson.isNotEmpty) {
    try {
      final decoded = jsonDecode(extraJson);
      if (decoded is Map) {
        for (final e in _stringKeyMap(decoded).entries) {
          merged.putIfAbsent(e.key, () => e.value);
        }
      }
    } catch (_) {
      stderr.writeln('CODEF_REQUEST_JSON 파싱 실패 — 무시');
    }
  }

  return merged;
}

/// CODEF 상품 POST (codef-node httpSender 와 동일).
Future<String> codefProductRaw({
  required String baseUrl,
  required String productPath,
  required String bearer,
  required Map<String, dynamic> body,
}) async {
  final uri = codefJoinedProductUri(baseUrl, productPath);
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
      final loc = 'POST $uri';
      final hint404 = res.statusCode == 404 ||
              raw.contains('CF-00404') ||
              raw.contains('NOT_FOUND 404')
          ? ' CODEF 문서의 «요청 URL»과 경로가 같은지, 개발 키면 CODEF_BASE_URL=https://development.codef.io·운영 키면 https://api.codef.io 인지 확인하세요.'
          : '';
      throw StateError('CODEF HTTP ${res.statusCode} ($loc)$hint404: $raw');
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

/// CF-00404·HTTP 404 등 «상품 URL/호스트 불일치» 로 보일 때만 다른 후보를 시도합니다.
bool codefErrorLooksLikeWrongProductUrl(Object e) {
  final s = e.toString();
  return s.contains('CF-00404') ||
      s.contains('CODEF HTTP 404') ||
      s.contains('NOT_FOUND 404');
}

/// `/public/each/pp/` ↔ 구 `/public/pp/` 등 문서·환경 차이를 흡수합니다.
List<String> bffCodefNhisPathCandidatesFromPrimary(String primaryPath) {
  final primary = primaryPath.trim();
  final normalized = primary.startsWith('/') ? primary : '/$primary';

  final pathCandidates = <String>[];
  void addPath(String p) {
    final q = p.trim().startsWith('/') ? p.trim() : '/${p.trim()}';
    if (!pathCandidates.contains(q)) pathCandidates.add(q);
  }

  addPath(normalized);
  final hasEach = normalized.contains('/public/each/pp/');
  final hasLegacy =
      normalized.contains('/public/pp/') && !hasEach;
  if (hasLegacy) {
    addPath(normalized.replaceAll('/public/pp/', '/public/each/pp/'));
  }
  if (hasEach) {
    addPath(normalized.replaceAll('/public/each/pp/', '/public/pp/'));
  }
  return pathCandidates;
}

/// 사용자 설정 우선, 이어서 api·development·sandbox.
List<String> bffCodefBaseUrlCandidates(Map<String, String> env) {
  final userBase = (env['CODEF_BASE_URL'] ?? '').trim();
  final baseCandidates = <String>[];
  void addBase(String b) {
    final t = b.trim();
    if (t.isEmpty) return;
    if (!baseCandidates.contains(t)) baseCandidates.add(t);
  }

  addBase(userBase);
  addBase('https://api.codef.io');
  addBase('https://development.codef.io');
  addBase('https://sandbox.codef.io');
  if (baseCandidates.isEmpty) {
    baseCandidates.add('https://api.codef.io');
  }
  return baseCandidates;
}

/// 국민건강보험 진료·투약(CODEF): 문서상 `/public/each/pp/` 와 구 `/public/pp/` 가 섞여 있고,
/// 호스트(api·development·sandbox) 조합에 따라 404가 나는 경우가 있어 후보를 순서대로 시도합니다.
Future<String> codefNhisTreatmentProductRaw({
  required Map<String, String> env,
  required String bearer,
  required Map<String, dynamic> body,
}) async {
  const defaultPath =
      '/v1/kr/public/each/pp/nhis-insurance-treatment-information';
  final fromEnv = (env['CODEF_NHIS_TREATMENT_PATH'] ?? '').trim();
  final primary = fromEnv.isNotEmpty ? fromEnv : defaultPath;
  final pathCandidates = bffCodefNhisPathCandidatesFromPrimary(primary);
  final baseCandidates = bffCodefBaseUrlCandidates(env);

  Object? lastErr;
  for (final base in baseCandidates) {
    for (final path in pathCandidates) {
      try {
        final out = await codefProductRaw(
          baseUrl: base,
          productPath: path,
          bearer: bearer,
          body: body,
        );
        try {
          final map = jsonDecode(out) as Map<String, dynamic>;
          final res = map['result'];
          if (res is Map) {
            final c = '${res['code'] ?? ''}'.trim();
            if (c == 'CF-00404') {
              lastErr = StateError('CODEF HTTP 200 result CF-00404: $out');
              continue;
            }
          }
        } catch (_) {
          // JSON 아님 등은 그대로 성공 처리
        }
        // ignore: avoid_print
        print('CODEF NHIS treatment OK: $base$path');
        return out;
      } catch (e) {
        lastErr = e;
        if (!codefErrorLooksLikeWrongProductUrl(e)) rethrow;
      }
    }
  }
  throw lastErr ??
      StateError('CODEF NHIS 진료·투약: base·path 후보에서 CF-00404/404');
}

/// `/v1/medications` 용: `.env` 에 `BFF_USE_CODEF_FOR_MEDICATIONS=true` 이고
/// `CODEF_CLIENT_*` + ([CODEF_MEDICATION_PATH] 또는 [CODEF_NHIS_TREATMENT_PATH]) 가 있을 때만 CODEF 호출.
/// 미설정·오류 시 null → 스텁 응답.
Future<Map<String, dynamic>?> fetchMedicationsFromCodef({
  required Map<String, String> env,
  required String phoneDigits,
  String? connectedIdOverride,
  String displayName = '',
  String gender = '',
}) async {
  if (!_truthy(env['BFF_USE_CODEF_FOR_MEDICATIONS'])) return null;

  final path = bffResolvedMedicationProductPath(env);
  final id = (env['CODEF_CLIENT_ID'] ?? '').trim();
  final secret = (env['CODEF_CLIENT_SECRET'] ?? '').trim();
  if (id.isEmpty || secret.isEmpty || path.isEmpty) return null;

  final connectedId =
      (connectedIdOverride ?? env['CODEF_CONNECTED_ID'] ?? '').trim();
  final orgEnv =
      (env['CODEF_HW_ORGANIZATION'] ?? env['CODEF_ORGANIZATION'] ?? '').trim();
  /// 틸코 병합 본문과 동일: 비우면 건보 공공 상품 기본 기관코드(0002).
  final org =
      orgEnv.isNotEmpty ? orgEnv : codefNhisOrganizationDefault;

  final body = <String, dynamic>{};
  if (connectedId.isNotEmpty) body['connectedId'] = connectedId;
  body['organization'] = org;
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
      throw StateError(
        'CODEF_MEDICATION_PATH(또는 CODEF_NHIS_TREATMENT_PATH) 는 / 로 시작해야 합니다.',
      );
    }
    final pathLower = path.toLowerCase();
    /// 문서상 진료·투약 상품은 connectedId·전화만으로는 부족하고 loginType 조합이 필요한 경우가 많습니다.
    if (pathLower.contains('nhis-insurance-treatment')) {
      body.putIfAbsent(
        'loginType',
        () => (env['CODEF_NHIS_LOGINTYPE'] ?? '5').trim(),
      );
      body.putIfAbsent(
        'loginTypeLevel',
        () => (env['CODEF_NHIS_LOGINTYPE_LEVEL'] ?? '1').trim(),
      );
    }
    if (pathLower.contains('connectedid-list') ||
        pathLower.contains('/v1/account/')) {
      throw StateError(
        'CODEF_MEDICATION_PATH 가 계정/연동 목록 API($path)를 가리킵니다. '
        'developer.codef.io 에서 「국민건강보험공단 건보진료정보」등 복약·진료 상품의 '
        '요청 URL 경로를 그대로 넣어야 합니다. connectedId-list 는 약 목록이 아닙니다.',
      );
    }
    final bearer = await _codefToken.token(clientId: id, clientSecret: secret);
    final pathCandidates = bffCodefNhisPathCandidatesFromPrimary(path);
    final baseCandidates = bffCodefBaseUrlCandidates(env);

    Object? lastErr;
    for (final baseTry in baseCandidates) {
      for (final pathTry in pathCandidates) {
        try {
          final decoded = await codefProductRaw(
            baseUrl: baseTry,
            productPath: pathTry,
            bearer: bearer,
            body: body,
          );
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          final result = map['result'];
          if (result is Map) {
            final c = '${result['code'] ?? ''}'.trim();
            if (c == 'CF-00404') {
              lastErr = StateError('CODEF HTTP 200 result CF-00404: $decoded');
              continue;
            }
          }
          final items = bffMapCodefRootToMedicationItems(map);
          String? code;
          String? message;
          if (result is Map) {
            code = '${result['code'] ?? ''}';
            message = '${result['message'] ?? ''}';
          }
          final hint = bffCodefNhisTreatResultHintKo(code, message);

          final extractedId = parseConnectedIdFromCodefRootMap(map);
          final cidOut = (extractedId != null && extractedId.trim().isNotEmpty)
              ? extractedId.trim()
              : (connectedId.isEmpty ? null : connectedId);

          // ignore: avoid_print
          print('CODEF medications OK: $baseTry$pathTry');
          return {
            'items': items,
            'meta': {
              'source': 'codef',
              'phone': phoneDigits,
              'connectedId': cidOut,
              'productPath': pathTry,
              'codefBaseTried': baseTry,
              'codefResultCode': code,
              'codefResultMessage': message,
              if (hint != null && hint.isNotEmpty) 'note': hint,
            },
          };
        } catch (e) {
          lastErr = e;
          if (!codefErrorLooksLikeWrongProductUrl(e)) {
            stderr.writeln('CODEF medications 오류: $e');
            final hint = bffCodefFailureHintKo(e);
            return {
              'items': <Map<String, dynamic>>[],
              'meta': {
                'source': 'codef_error',
                'phone': phoneDigits,
                'error': '$e',
                if (hint != null && hint.isNotEmpty) 'note': hint,
              },
            };
          }
        }
      }
    }
    stderr.writeln('CODEF medications: base·path 후보 실패: $lastErr');
    final hintAll = bffCodefFailureHintKo(lastErr);
    return {
      'items': <Map<String, dynamic>>[],
      'meta': {
        'source': 'codef_error',
        'phone': phoneDigits,
        'error': '$lastErr',
        if (hintAll != null && hintAll.isNotEmpty) 'note': hintAll,
      },
    };
  } catch (e, st) {
    stderr.writeln('CODEF medications 오류: $e\n$st');
    final hint = bffCodefFailureHintKo(e);
    return {
      'items': <Map<String, dynamic>>[],
      'meta': {
        'source': 'codef_error',
        'phone': phoneDigits,
        'error': '$e',
        if (hint != null && hint.isNotEmpty) 'note': hint,
      },
    };
  }
}

/// CODEF 본문에서 `connectedId` 후보 — [parseConnectedIdFromCodefRootMap] 위임.
String? bffExtractConnectedIdFromCodefRoot(Map<String, dynamic> root) =>
    parseConnectedIdFromCodefRootMap(root);

/// CODEF 건강iN/건보 진료·투약 JSON 루트에서 앱/BFF 공통 약 행 목록을 뽑습니다.
/// 구현은 [codefRootToMedicationItems] (중첩·한글 필드명·문자열 JSON data 대응).
List<Map<String, dynamic>> bffMapCodefRootToMedicationItems(Map<String, dynamic> root) =>
    codefRootToMedicationItems(root);

Map<String, dynamic> _stringKeyMap(Map raw) {
  final out = <String, dynamic>{};
  for (final e in raw.entries) {
    out['${e.key}'] = e.value;
  }
  return out;
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
