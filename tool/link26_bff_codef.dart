// link26_bff 지원 모듈 — `dart run tool/link26_bff.dart` 에서 import.
//
// 포함: `.env` 병합, e약은요 serviceKey, **틸코 NHIS 응답 → 약 행** 매핑(`bffMapCodefRootToMedicationItems`) 등.
//
// 아래 CODEF HTTP 클라이언트(oauth·상품 POST·헬스 프로브·`fetchMedicationsFromCodef`)는
// 레포에 **소스로 남아 있으나** `link26_bff.dart` 라우터에서는 더 이상 호출하지 않습니다.
// (복약 실데이터는 틸코 `POST …/tilko-hira-medications` 만 사용.)
//
// CODEF 요청 형식은 codef-io/codef-node 샘플과 동일했던 시절의 기록:
// - OAuth: https://oauth.codef.io/oauth/token
// - 상품: POST baseUrl + path, Body = Uri.encodeComponent(jsonEncode(map))

import 'dart:convert';
import 'dart:io';

import 'package:link26_app/core/services/codef_flow_connected_id_parse.dart';
import 'package:link26_app/integrations/codef/codef_medication_mapper.dart';
import 'package:link26_app/tool_support/bff_dotenv_line_scan.dart';
import 'package:path/path.dart' as p;

/// 프로젝트 루트 환경을 읽습니다.
///
/// 1) `assets/env/dotenv` — Flutter 빌드 전 `sync_dotenv_asset.ps1` 가 루트 `.env` 를 복사한 파일.
/// 2) `.env` — 루트(덮어쓰기 우선). 단, **같은 키에 값이 비어 있으면** 1)에서 이미 채워진 값을
///    지우지 않습니다(`.env`에 `TILKO_API_KEY=` 플레이스홀만 있을 때 dotenv의 키가 날아가던 버그 방지).
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
      merged.addAll(_parseDotEnv(BffDotenvLineScan.stripUtf8Bom(f.readAsStringSync())));
    }
  }

  /// `.env` 전용: 빈 문자열로 기존 비어 있지 않은 값을 덮어쓰지 않음.
  void mergeEnvFileNoEmptyWipe(String relativePath) {
    final f = File(p.join(root, relativePath));
    if (!f.existsSync()) return;
    final parsed = _parseDotEnv(BffDotenvLineScan.stripUtf8Bom(f.readAsStringSync()));
    for (final e in parsed.entries) {
      final incoming = e.value.trim();
      final existing = (merged[e.key] ?? '').trim();
      if (incoming.isEmpty && existing.isNotEmpty) continue;
      merged[e.key] = e.value;
    }
  }

  mergeFile(p.join('assets', 'env', 'dotenv'));
  mergeEnvFileNoEmptyWipe('.env');

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

  if ((merged['TILKO_API_KEY'] ?? '').trim().isEmpty) {
    for (final rel in <String>['.env', p.join('assets', 'env', 'dotenv')]) {
      final f = File(p.join(root, rel));
      if (!f.existsSync()) continue;
      final hit = BffDotenvLineScan.scanTilkoApiKeyLineByLine(f.readAsStringSync());
      if (hit != null && hit.trim().isNotEmpty) {
        merged['TILKO_API_KEY'] = hit.trim();
        // ignore: avoid_print
        stderr.writeln(
          '[BFF env] TILKO_API_KEY: 일반 병합에서 비어 있어 $rel 원문 줄 스캔으로 복구했습니다.',
        );
        break;
      }
    }
  }

  return merged;
}

/// `dart run tool/link26_bff.dart` 가 들어 있는 레포 루트를 우선합니다.
///
/// 예전에는 cwd 에 아무 `.env`만 있어도 그 폴더를 썼는데, 다른 프로젝트 터미널에서
/// BFF를 실행하면 Link26 의 틸코 키가 아닌 빈 `.env`를 읽어 `TILKO_API_KEY` 가
/// 비는 문제가 생길 수 있어, [pubspec.yaml] 이 보이는 script 기준 루트를 먼저 씁니다.
String _link26ProjectRoot() {
  final scriptRoot = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..'),
  );
  if (File(p.join(scriptRoot, 'pubspec.yaml')).existsSync()) {
    return scriptRoot;
  }
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

/// BFF 기동 로그용. 키 **값**은 출력하지 않습니다.
void logBffDotEnvBootstrap(Map<String, String> env) {
  final root = _link26ProjectRoot();
  // ignore: avoid_print
  stdout.writeln('  [BFF env] resolved repo root:');
  // ignore: avoid_print
  stdout.writeln('    $root');
  final dotPath = p.join(root, 'assets', 'env', 'dotenv');
  final envPath = p.join(root, '.env');
  // ignore: avoid_print
  stdout.writeln(
    '  [BFF env] assets/env/dotenv: ${File(dotPath).existsSync() ? "exists" : "MISSING"}',
  );
  // ignore: avoid_print
  stdout.writeln(
    '  [BFF env] .env: ${File(envPath).existsSync() ? "exists" : "MISSING"}',
  );
  final tilkoLen = (env['TILKO_API_KEY'] ?? '').trim().length;
  final tilkoHost = (env['TILKO_API_HOST'] ?? 'https://dev.tilko.net').trim();
  // ignore: avoid_print
  stdout.writeln(
    '  [BFF env] TILKO_API_KEY loaded length: $tilkoLen (0이면 심평원·틸코 플로우 불가)',
  );
  // ignore: avoid_print
  stdout.writeln(
    '  [BFF env] TILKO_API_HOST=$tilkoHost '
    '(데모 키→dev.tilko.net · 운영 키→api.tilko.net, 호스트·키 짝이 맞아야 함)',
  );
  if (tilkoLen == 0) {
    // ignore: avoid_print
    stderr.writeln(
      '  [BFF env] 경고: TILKO_API_KEY 비어 있음 — 위 경로의 .env / assets/env/dotenv 를 확인하고, '
      '앱 NHIS_BASE_URL 포트와 실제 떠 있는 BFF 포트가 같은지(중복 실행)도 확인하세요.',
    );
  }
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
    val = BffDotenvLineScan.stripQuotes(val);
    out[key] = val;
  }
  return out;
}

bool _truthy(String? s) {
  final t = (s ?? '').trim().toLowerCase();
  return t == 'true' || t == '1' || t == 'yes';
}

/// link26_bff.dart 헬스 응답용.
bool bffEnvTruthy(String? s) => _truthy(s);

/// `.env` 오타 등으로 `.../public/cach/pp/...` 가 들어오면 CODEF가 302 등으로 응답할 수 있어
/// 문서 경로인 `/public/each/pp/` 로 보정합니다.
///
/// 건보 진료·투약 상품 슬러그 `nhis-insurance-treatment-information` 이 복붙 과정에서
/// `nhis insurance-treatment-information` 처럼 하이픈이 공백으로 바뀌는 경우가 있어
/// CODEF가 302·잘못된 엔드포인트로 응답할 수 있습니다.
String bffNormalizeCodefProductPathTypos(String path) {
  var p = path.trim();
  if (p.contains('/public/cach/pp/')) {
    stderr.writeln(
      'CODEF: 경로에 /public/cach/pp/ 오타 감지 — /public/each/pp/ 로 보정했습니다.',
    );
    p = p.replaceAll('/public/cach/pp/', '/public/each/pp/');
  }
  final beforeSlugFix = p;
  p = p
      .replaceAll(
        RegExp(r'nhis\s+insurance-treatment-information'),
        'nhis-insurance-treatment-information',
      )
      .replaceAll(
        RegExp(r'nhis-insurance\s+treatment-information'),
        'nhis-insurance-treatment-information',
      );
  if (p != beforeSlugFix) {
    stderr.writeln(
      'CODEF: 경로에 건보 진료·투약 슬러그 공백 오타 감지 — '
      'nhis-insurance-treatment-information 으로 보정했습니다.',
    );
  }
  return p;
}

/// `CODEF_MEDICATION_PATH` 우선, 비어 있으면 틸코·건보 플로우와 동일한
/// `CODEF_NHIS_TREATMENT_PATH` 를 씁니다(같은 건보 진료·투약 상품 URL인 경우).
String bffResolvedMedicationProductPath(Map<String, String> env) {
  final a = (env['CODEF_MEDICATION_PATH'] ?? '').trim();
  if (a.isNotEmpty) return bffNormalizeCodefProductPathTypos(a);
  return bffNormalizeCodefProductPathTypos(
    (env['CODEF_NHIS_TREATMENT_PATH'] ?? '').trim(),
  );
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
      req.followRedirects = false;
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

/// CODEF 게이트웨이가 주는 [Location] 값 정리(`<https://…>`·RFC5988 등).
String? normalizeCodefRedirectLocation(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.length >= 2 && s.startsWith('<') && s.endsWith('>')) {
    s = s.substring(1, s.length - 1).trim();
  }
  final semi = s.indexOf(';');
  if (semi >= 0) {
    s = s.substring(0, semi).trim();
  }
  return s.isEmpty ? null : s;
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
  if (s.contains('CF-00017') || s.contains('"code":"CF-00017"')) {
    return 'CODEF 클라이언트 종류와 호스트가 맞지 않습니다(CF-00017). '
        '샌드박스 클라이언트면 CODEF_BASE_URL=https://sandbox.codef.io, '
        '개발(데모) 키면 https://development.codef.io, 운영이면 https://api.codef.io 를 콘솔·키 유형과 맞추세요.';
  }
  if (RegExp(r'CODEF HTTP (301|302|303|307|308)').hasMatch(s)) {
    return 'CODEF 게이트웨이가 HTTP 리다이렉트(301·302·303·307·308)로 응답했습니다. '
        'BFF를 최신 `tool/link26_bff_codef.dart`로 맞춘 뒤 재시작했는지, 콘솔에 '
        '`CODEF: HTTP … Location=` 로그가 찍히는지 확인하세요. '
        '계속되면 CODEF_BASE_URL·클라이언트 키 종류(샌드박스·개발·운영) 짝과 '
        'CODEF_NHIS_TREATMENT_PATH(/public/each/pp/ 포함)를 developer.codef.io 와 맞추세요. '
        '(/public/cach/pp/ 등 경로 오타도 302를 유발할 수 있습니다.)';
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
  if (c == 'CF-00017') {
    return 'CODEF 클라이언트와 호스트가 짝이 아닙니다(CF-00017). '
        '샌드박스 클라이언트는 CODEF_BASE_URL=https://sandbox.codef.io, '
        '개발(데모)은 https://development.codef.io, 운영은 https://api.codef.io 를 콘솔 안내와 맞추세요.';
  }
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
///
/// CODEF·게이트웨이가 **301·302·303·307·308** 으로 최종 URL을 안내하는 경우가 있어,
/// Dart [HttpClient] 가 POST+302 리다이렉트를 자동으로 따라가지 않아 302만 보이는 문제를 막기 위해
/// [Location] 헤더를 수동으로 따라갑니다(최대 [maxRedirects]회). POST 본문·Bearer는 유지합니다.
Future<String> codefProductRaw({
  required String baseUrl,
  required String productPath,
  required String bearer,
  required Map<String, dynamic> body,
  int maxRedirects = 6,
}) async {
  var uri = codefJoinedProductUri(baseUrl, productPath);
  final client = HttpClient();
  final encoded = Uri.encodeQueryComponent(jsonEncode(body));
  try {
    for (var hop = 0; hop <= maxRedirects; hop++) {
      final req = await client.postUrl(uri);
      // POST+302 는 Dart 가 자동으로 따라가지 않음. 수동 리다이렉트만 쓰기 위해 명시적으로 끔.
      req.followRedirects = false;
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      req.write(encoded);
      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();
      final code = res.statusCode;

      // HttpStatus 상수와 무관하게 숫자로 판별(툴 체인·이관 시 혼동 방지).
      // 303: 일부 게이트웨이가 잘못 쓰는 경우가 있어 POST 유지로 동일 본문 재전송.
      final manualRedirect = code == 301 ||
          code == 302 ||
          code == 303 ||
          code == 307 ||
          code == 308;
      if (manualRedirect) {
        final locationRaw = res.headers.value(HttpHeaders.locationHeader);
        final location = normalizeCodefRedirectLocation(locationRaw);
        if (location == null) {
          throw StateError(
            'CODEF HTTP $code (POST $uri) without Location: $raw',
          );
        }
        if (hop == maxRedirects) {
          throw StateError(
            'CODEF redirect limit ($maxRedirects) POST $uri → $location',
          );
        }
        final next = uri.resolve(location);
        // ignore: avoid_print
        stderr.writeln('CODEF: HTTP $code Location=$location → POST $next');
        uri = next;
        continue;
      }

      if (code != HttpStatus.ok) {
        final loc = 'POST $uri';
        final hint404 = code == 404 ||
                raw.contains('CF-00404') ||
                raw.contains('NOT_FOUND 404')
            ? ' CODEF 문서의 «요청 URL»과 경로가 같은지, 개발 키면 CODEF_BASE_URL=https://development.codef.io·운영 키면 https://api.codef.io 인지 확인하세요.'
            : '';
        throw StateError('CODEF HTTP $code ($loc)$hint404: $raw');
      }
      try {
        return Uri.decodeQueryComponent(raw);
      } catch (_) {
        return raw;
      }
    }
    throw StateError('CODEF POST $uri: unexpected redirect loop exit');
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

/// 잘못된 상품 URL이 아니라 호스트·리다이렉트 등으로 다음 base 후보를 시도할 만한 HTTP 오류.
bool codefErrorLooksLikeRetryableTransport(Object e) {
  final s = e.toString();
  return s.contains('CODEF HTTP 302') ||
      s.contains('CODEF HTTP 301') ||
      s.contains('CODEF HTTP 303') ||
      s.contains('CODEF HTTP 307') ||
      s.contains('CODEF HTTP 308');
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
///
/// `CODEF_BASE_URL` 이 비어 있고 콘솔에만 적은 `CODEF_API_HOST` 가 있을 때 그 값을
/// 첫 후보로 씁니다(이전에는 무시되어 잘못된 기본 호스트로 상품만 호출되는 경우가 있었음).
/// 둘 다 있으면 둘 다 후보에 넣어 `CF-00003`/`CF-00017` 시 다음 조합을 시도합니다.
List<String> bffCodefBaseUrlCandidates(Map<String, String> env) {
  final userBase = (env['CODEF_BASE_URL'] ?? '').trim();
  final apiHost = (env['CODEF_API_HOST'] ?? '').trim();
  final baseCandidates = <String>[];
  void addBase(String b) {
    final t = b.trim();
    if (t.isEmpty) return;
    if (!baseCandidates.contains(t)) baseCandidates.add(t);
  }

  addBase(userBase);
  addBase(apiHost);
  addBase('https://api.codef.io');
  addBase('https://development.codef.io');
  addBase('https://sandbox.codef.io');
  if (baseCandidates.isEmpty) {
    baseCandidates.add('https://api.codef.io');
  }
  return baseCandidates;
}

/// CODEF 상품 응답 JSON(디코드된 문자열)에서 `result.code` 추출.
String? bffCodefResultCodeFromDecoded(String decoded) {
  try {
    final map = jsonDecode(decoded) as Map<String, dynamic>?;
    final res = map?['result'];
    if (res is Map) {
      return '${res['code'] ?? ''}'.trim();
    }
  } catch (_) {}
  return null;
}

/// HTTP 200 이지만 호스트·상품 불일치로 다른 base 를 시도할 만한 코드.
bool bffCodefHttp200ShouldRetryOtherHost(String decoded) {
  final c = bffCodefResultCodeFromDecoded(decoded) ?? '';
  return c == 'CF-00404' || c == 'CF-00003' || c == 'CF-00017';
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
  final fromEnv = bffNormalizeCodefProductPathTypos(
    (env['CODEF_NHIS_TREATMENT_PATH'] ?? '').trim(),
  );
  final primary = fromEnv.isNotEmpty ? fromEnv : defaultPath;
  final pathCandidates = bffCodefNhisPathCandidatesFromPrimary(primary);
  final baseCandidates = bffCodefBaseUrlCandidates(env);

  Object? lastErr;
  String? lastDecodedSoftFail;
  String? firstDecodedSoftFail;
  for (final base in baseCandidates) {
    for (final path in pathCandidates) {
      try {
        final out = await codefProductRaw(
          baseUrl: base,
          productPath: path,
          bearer: bearer,
          body: body,
        );
        Map<String, dynamic>? map;
        try {
          map = jsonDecode(out) as Map<String, dynamic>?;
        } catch (_) {
          // ignore: avoid_print
          print('CODEF NHIS treatment OK: $base$path');
          return out;
        }
        final res = map?['result'];
        if (res is Map) {
          final c = '${res['code'] ?? ''}'.trim();
          if (c == 'CF-00404') {
            lastErr = StateError('CODEF HTTP 200 result CF-00404: $out');
            continue;
          }
          if (bffCodefHttp200ShouldRetryOtherHost(out)) {
            firstDecodedSoftFail ??= out;
            lastDecodedSoftFail = out;
            lastErr = StateError('CODEF HTTP 200 result $c: $out');
            continue;
          }
        }
        // ignore: avoid_print
        print('CODEF NHIS treatment OK: $base$path');
        return out;
      } catch (e) {
        lastErr = e;
        if (codefErrorLooksLikeWrongProductUrl(e) ||
            codefErrorLooksLikeRetryableTransport(e)) {
          continue;
        }
        rethrow;
      }
    }
  }
  final toReturn = firstDecodedSoftFail ?? lastDecodedSoftFail;
  if (toReturn != null) {
    // ignore: avoid_print
    print(
      'CODEF NHIS treatment: 모든 base·path 후보가 CF-00003/00017/00404 — '
      '설정 호스트 우선 응답 반환',
    );
    return toReturn;
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
    Map<String, dynamic>? lastSoftFailMap;
    String? lastSoftBase;
    String? lastSoftPath;
    Map<String, dynamic>? firstSoftFailMap;
    String? firstSoftBase;
    String? firstSoftPath;
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
            if (bffCodefHttp200ShouldRetryOtherHost(decoded)) {
              firstSoftFailMap ??= map;
              firstSoftBase ??= baseTry;
              firstSoftPath ??= pathTry;
              lastSoftFailMap = map;
              lastSoftBase = baseTry;
              lastSoftPath = pathTry;
              lastErr = StateError('CODEF HTTP 200 result $c: $decoded');
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
          if (codefErrorLooksLikeWrongProductUrl(e) ||
              codefErrorLooksLikeRetryableTransport(e)) {
            continue;
          }
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
    final failMap = firstSoftFailMap ?? lastSoftFailMap;
    final reportBase = firstSoftBase ?? lastSoftBase;
    final reportPath = firstSoftPath ?? lastSoftPath;
    if (failMap != null) {
      final map = failMap;
      final result = map['result'];
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
      print(
        'CODEF medications: 모든 호스트·경로 시도 후에도 CF-00003/00017 등 — '
        '$reportBase$reportPath',
      );
      return {
        'items': items,
        'meta': {
          'source': 'codef',
          'phone': phoneDigits,
          'connectedId': cidOut,
          'productPath': reportPath ?? path,
          'codefBaseTried': reportBase ?? '',
          'codefResultCode': code,
          'codefResultMessage': message,
          if (hint != null && hint.isNotEmpty) 'note': hint,
          'codefExhaustedHostCandidates': true,
        },
      };
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
