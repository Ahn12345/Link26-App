// Link26 최소 BFF — Node 없이 `dart run tool/link26_bff.dart` 로 실행.
//
// 제품 흐름(의도): 로그인/가입 후 틸코 간편인증 → (CODEF 등) 건강보험 진료·투약 정보 → 본인 복약.
// 이 Dart BFF는 그중 틸코 프록시·공공 e약은요·CODEF 상품(/v1/medications)을 한 PC에서 돕는 역할입니다.
// 앱은 NHIS_BASE_URL 로만 이 BFF에 붙고, 공단/틸코 비밀키는 루트 `.env` 에 둡니다.
//
// 포트: 환경변수 PORT 가 있으면 그 포트만 사용 (이미 다른 터미널에서 쓰 중이면 errno 10048).
// PORT 를 비우고 실행하면 8787부터 빈 포트를 순서대로 잡습니다 — VS·PowerShell 이중 실행 시
// 서로 다른 포트가 될 수 있으니, 앱 NHIS_BASE_URL 은 실제로 뜬 포트에 맞출 것.
// 전부 실패 시 OS 임의 포트(0) 사용.
//
// Windows PowerShell 고정 포트: $env:PORT="8788"; dart run tool/link26_bff.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

import 'link26_bff_codef.dart';

Future<void> main() async {
  final server = await _bindServer();
  final port = server.port;

  // ignore: avoid_print
  stdout.writeln('');
  // ignore: avoid_print
  stdout.writeln('>>> link26-bff (Dart) 실제 포트: $port <<<');
  // ignore: avoid_print
  stdout.writeln('    http://127.0.0.1:$port/health');
  // ignore: avoid_print
  stdout.writeln('    에뮬용 .env: NHIS_BASE_URL=http://10.0.2.2:$port');
  // ignore: avoid_print
  stdout.writeln('');
  // ignore: avoid_print
  stdout.writeln(
    '  POST /v1/signup  POST /v1/login  GET /v1/medications  GET /health\n'
    '  GET /v1/public/easy-drug  POST /v1/tilko/hira-simple-auth  POST /v1/flow/tilko-codef-treatment',
  );
  final bootEnv = loadBffDotEnv();
  final pSu = (bootEnv['NHIS_PROXY_SIGNUP_URL'] ?? '').trim();
  final pLo = (bootEnv['NHIS_PROXY_LOGIN_URL'] ?? '').trim();
  if (pSu.isNotEmpty || pLo.isNotEmpty) {
    // ignore: avoid_print
    stdout.writeln(
      '  가입/로그인 프록시: signup=${pSu.isNotEmpty} login=${pLo.isNotEmpty} (.env NHIS_PROXY_*)',
    );
  }
  _printEnvReadinessSummary(bootEnv);

  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<HttpServer> _bindServer() async {
  final envRaw = Platform.environment['PORT']?.trim();
  if (envRaw != null && envRaw.isNotEmpty) {
    final p = int.tryParse(envRaw);
    if (p == null || p <= 0 || p > 65535) {
      stderr.writeln('잘못된 PORT=$envRaw');
      exit(64);
    }
    try {
      return await HttpServer.bind(InternetAddress.anyIPv4, p);
    } catch (e) {
      stderr.writeln('PORT=$p 바인드 실패: $e');
      stderr.writeln('');
      stderr.writeln('원인: 이 포트를 이미 쓰는 프로세스가 있습니다(다른 터미널에서 BFF 중복 실행 등).');
      stderr.writeln('해결 택1 — 기존 것만 쓰기: 다른 터미널의 link26_bff 를 하나만 남기고 나머지는 Ctrl+C 로 종료.');
      stderr.writeln('해결 택2 — PID 종료(PowerShell):');
      stderr.writeln(
        '  Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue '
        '| Select-Object OwningProcess',
      );
      stderr.writeln('  Stop-Process -Id <위 OwningProcess> -Force');
      stderr.writeln('해결 택3 — 다른 포트: \$env:PORT=8788; dart run tool/link26_bff.dart');
      stderr.writeln('          (앱 .env 의 NHIS_BASE_URL 포트도 같이 변경)');
      stderr.writeln('해결 택4 — 자동으로 빈 포트: Remove-Item Env:PORT; dart run tool/link26_bff.dart');
      stderr.writeln('');
      exit(1);
    }
  }

  // 선호 포트들 시도 (어떤 종류의 바인드 예외든 잡음 — Windows 호환)
  const preferredStart = 8787;
  const scanCount = 30;
  for (var i = 0; i < scanCount; i++) {
    final p = preferredStart + i;
    try {
      return await HttpServer.bind(InternetAddress.anyIPv4, p);
    } catch (_) {
      if (i == 0) {
        stderr.writeln(
          '$preferredStart 대역 사용 중이면 다음 포트를 시도합니다… '
          '(모두 안 되면 임의 포트로 뜹니다)',
        );
      }
    }
  }

  stderr.writeln(
    '$preferredStart~${preferredStart + scanCount - 1} 모두 실패 → '
    'OS 임의 포트(0)로 바인드합니다. 아래에 나온 포트로 .env 를 맞추세요.',
  );
  return HttpServer.bind(InternetAddress.anyIPv4, 0);
}

void _printEnvReadinessSummary(Map<String, String> env) {
  final pub = bffPublicDataConfigured(env);
  final tilko = (env['TILKO_API_KEY'] ?? '').trim().isNotEmpty;
  final codefOAuth =
      (env['CODEF_CLIENT_ID'] ?? '').trim().isNotEmpty &&
          (env['CODEF_CLIENT_SECRET'] ?? '').trim().isNotEmpty;
  final codefMeds = bffMedicationsCodefConfigured(env);
  // ignore: avoid_print
  stdout.writeln('');
  // ignore: avoid_print
  stdout.writeln(
    '  [.env 요약 — false 이면 해당 API는 503/스킵될 수 있음]',
  );
  // ignore: avoid_print
  stdout.writeln(
    '    공공 e약은요 serviceKey: $pub  (PUBLIC_DATA_SERVICE_KEY / DATA_GO_KR_SERVICE_KEY / NHIS_SERVICE_KEY)',
  );
  // ignore: avoid_print
  stdout.writeln('    틸코 TILKO_API_KEY: $tilko');
  // ignore: avoid_print
  stdout.writeln(
    '    CODEF OAuth(클라이언트): $codefOAuth  |  복약상품 경로까지: $codefMeds  '
    '(BFF_USE_CODEF_FOR_MEDICATIONS + CODEF_MEDICATION_PATH 또는 CODEF_NHIS_TREATMENT_PATH)',
  );
  // ignore: avoid_print
  stdout.writeln('');
}

/// /health 전용: 어떤 env 키가 serviceKey 소스인지(민감값 미포함).
String? _publicDataKeySourceForHealth(Map<String, String> env) {
  const keys = [
    'PUBLIC_DATA_SERVICE_KEY',
    'DATA_GO_KR_SERVICE_KEY',
    'NHIS_SERVICE_KEY',
  ];
  for (final k in keys) {
    if ((env[k] ?? '').trim().isNotEmpty) return k;
  }
  return null;
}

Future<void> _handle(HttpRequest request) async {
  try {
    final path = request.uri.path;
    final method = request.method;

    if (method == 'GET' && path == '/health') {
      final env = loadBffDotEnv();
      final probe = await codefHealthProbe(env);
      final codefMedicationsReady = bffMedicationsCodefConfigured(env);
      final useCodefMeds = bffEnvTruthy(env['BFF_USE_CODEF_FOR_MEDICATIONS']);
      final resolvedMedPath = bffResolvedMedicationProductPath(env);
      final medPathOk = resolvedMedPath.trim().isNotEmpty;
      await _json(request, 200, {
        'ok': true,
        'service': 'link26-bff-dart',
        'codef': probe,
        'tilko': {
          'configured': (env['TILKO_API_KEY'] ?? '').trim().isNotEmpty,
        },
        'publicData': {
          'configured': bffPublicDataConfigured(env),
          'serviceKeyFrom': _publicDataKeySourceForHealth(env) ?? 'none',
        },
        'medicationsSource':
            codefMedicationsReady ? 'codef' : 'stub',
        'medicationsConfig': {
          'bffUseCodefForMedications': useCodefMeds,
          'resolvedProductPath': resolvedMedPath,
          'productPathConfigured': medPathOk,
        },
        'authProxy': {
          'signup':
              (env['NHIS_PROXY_SIGNUP_URL'] ?? '').trim().isNotEmpty,
          'login': (env['NHIS_PROXY_LOGIN_URL'] ?? '').trim().isNotEmpty,
        },
      });
      return;
    }

    if (method == 'GET' && path == '/v1/public/easy-drug') {
      await _handleEasyDrug(request);
      return;
    }

    if (method == 'POST' && path == '/v1/tilko/hira-simple-auth') {
      final bodyStr = await _readBody(request);
      final env = loadBffDotEnv();
      try {
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        final c = TilkoHiraSimpleAuthClient.fromBffEnv(env);
        final res = await c.requestFromJsonMap(map);
        await _json(request, 200, {'ok': true, 'tilko': res});
      } catch (e, st) {
        // ignore: avoid_print
        print('BFF tilko: $e\n$st');
        await _json(request, 502, {'ok': false, 'detail': '$e'});
      }
      return;
    }

    if (method == 'POST' && path == '/v1/flow/tilko-codef-treatment') {
      final bodyStr = await _readBody(request);
      final env = loadBffDotEnv();
      try {
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        final tilkoMap = map['tilko'] as Map<String, dynamic>? ?? map;
        final codefExtra = map['codef_payload'] as Map<String, dynamic>? ?? {};
        final tilkoClient = TilkoHiraSimpleAuthClient.fromBffEnv(env);
        final tilkoRes = await tilkoClient.requestFromJsonMap(tilkoMap);
        final id = (env['CODEF_CLIENT_ID'] ?? '').trim();
        final secret = (env['CODEF_CLIENT_SECRET'] ?? '').trim();
        if (id.isEmpty || secret.isEmpty) {
          await _json(request, 200, {
            'ok': true,
            'tilko': tilkoRes,
            'codef': null,
            'notice': 'CODEF 클라이언트 미설정 — CODEF 호출 생략',
          });
          return;
        }
        final bearer = await bffCodefBearer(env);
        final merged = mergeCodefNhisTilkoTreatmentBody(
          env: env,
          codefExtra: codefExtra,
          tilkoMap: tilkoMap,
          tilkoRes: tilkoRes,
        );
        final raw = await codefNhisTreatmentProductRaw(
          env: env,
          bearer: bearer,
          body: merged,
        );
        final codefDecoded = jsonDecode(raw) as Map<String, dynamic>;
        String? cfCode;
        String? cfMsg;
        final resObj = codefDecoded['result'];
        if (resObj is Map) {
          cfCode = '${resObj['code'] ?? ''}'.trim();
          cfMsg = '${resObj['message'] ?? ''}'.trim();
        }
        final cfBusinessOk =
            cfCode == null || cfCode.isEmpty || cfCode == 'CF-00000';
        if (!cfBusinessOk) {
          final msgOut = (cfMsg ?? '').trim();
          final detailOut = msgOut.isNotEmpty ? msgOut : cfCode;
          final hint = bffCodefNhisTreatResultHintKo(cfCode, cfMsg) ??
              'CODEF 건보 진료·투약 조회에 실패했습니다.';
          await _json(request, 200, {
            'ok': false,
            'detail': detailOut,
            'hint_ko': hint,
            'tilko': tilkoRes,
            'codef': codefDecoded,
          });
          return;
        }
        final items = bffMapCodefRootToMedicationItems(codefDecoded);
        final extractedCid = bffExtractConnectedIdFromCodefRoot(codefDecoded);
        final sentCid = '${merged['connectedId'] ?? ''}'.trim();
        final echoCid = (extractedCid != null && extractedCid.isNotEmpty)
            ? extractedCid
            : (sentCid.isNotEmpty ? sentCid : null);
        final emptyParsed = items.isEmpty;
        await _json(request, 200, {
          'ok': true,
          'tilko': tilkoRes,
          'codef': codefDecoded,
          'items': items,
          if (echoCid != null && echoCid.isNotEmpty) 'connectedId': echoCid,
          'meta': {
            'source': 'tilko_codef_nhis',
            'codefResultCode': cfCode,
            'codefResultMessage': cfMsg,
            if (echoCid != null && echoCid.isNotEmpty) 'connectedId': echoCid,
            if (emptyParsed)
              'note':
                  'CODEF 응답은 정상(CF-00000)이나 앱이 인식한 복약 항목이 0건입니다. '
                  '실제 처방이 없거나, 응답 data 구조가 달라 약품명 필드를 찾지 못한 경우일 수 있습니다. '
                  'BFF 로그의 codef JSON을 확인하세요.',
          },
        });
      } catch (e, st) {
        // ignore: avoid_print
        print('BFF flow tilko-codef: $e\n$st');
        final hint = bffCodefFailureHintKo(e);
        var detail = '$e';
        if (e is StateError) {
          final m = e.toString();
          const p = 'Bad state: ';
          if (m.startsWith(p)) detail = m.substring(p.length);
        }
        final errBody = <String, dynamic>{
          'ok': false,
          'detail': detail,
        };
        if (hint != null) errBody['hint_ko'] = hint;
        // HTTP 200 — 앱이 `flow HTTP 502` 형태의 StateError 대신 본문 ok/hint 만 처리하도록.
        await _json(request, 200, errBody);
      }
      return;
    }

    if (method == 'POST' && path == '/v1/signup') {
      final bodyStr = await _readBody(request);
      final env = loadBffDotEnv();
      final proxy = (env['NHIS_PROXY_SIGNUP_URL'] ?? '').trim();
      if (proxy.isNotEmpty) {
        await _proxyPost(request, proxy, bodyStr);
        return;
      }
      Object echo;
      try {
        echo = bodyStr.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(bodyStr) as Object;
      } catch (_) {
        echo = {'_raw': bodyStr};
      }
      await _json(request, 200, {
        'ok': true,
        'flow': 'signup',
        'receivedAt': DateTime.now().toUtc().toIso8601String(),
        'gateway': 'stub',
        'received': echo,
      });
      return;
    }

    if (method == 'POST' && path == '/v1/login') {
      final bodyStr = await _readBody(request);
      final env = loadBffDotEnv();
      final proxy = (env['NHIS_PROXY_LOGIN_URL'] ?? '').trim();
      if (proxy.isNotEmpty) {
        await _proxyPost(request, proxy, bodyStr);
        return;
      }
      Object echo;
      try {
        echo = bodyStr.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(bodyStr) as Object;
      } catch (_) {
        echo = {'_raw': bodyStr};
      }
      await _json(request, 200, {
        'ok': true,
        'flow': 'login',
        'receivedAt': DateTime.now().toUtc().toIso8601String(),
        'gateway': 'stub',
        'received': echo,
      });
      return;
    }

    if (method == 'GET' && path == '/v1/medications') {
      final q = request.uri.queryParameters;
      final phone = q['phone'] ?? '';
      final env = loadBffDotEnv();
      final codefOn = bffMedicationsCodefConfigured(env);
      final cid = bffResolvedConnectedId(q, env);
      if (codefOn &&
          cid.isEmpty &&
          !bffAllowCodefWithoutConnectedId(env)) {
        await _json(request, 200, {
          'items': <Map<String, dynamic>>[],
          'meta': {
            'source': 'codef_missing_connected_id',
            'phone': phone,
            'note':
                'CODEF 상품(건강·공단)은 기관 연동 후 발급되는 connectedId가 필요합니다. '
                '앱 설정에서 저장했는지, 또는 BFF .env 의 CODEF_CONNECTED_ID 를 확인하세요. '
                '(테스트용으로만 BFF_ALLOW_CODEF_WITHOUT_CONNECTED_ID=true 가능)',
          },
        });
        return;
      }
      final codefRes = await fetchMedicationsFromCodef(
        env: env,
        phoneDigits: phone,
        connectedIdOverride: cid.isNotEmpty ? cid : null,
        displayName: q['displayName'] ?? '',
        gender: q['gender'] ?? '',
      );
      if (codefRes != null) {
        await _json(request, 200, codefRes);
        return;
      }
      await _json(request, 200, {
        'items': [
          {
            'name': '심사·데모 복약 안내',
            'dose': '-',
            'frequency': '1일 1회',
            'time': '09:00',
          },
          {
            'name': '종합비타민(예시)',
            'dose': '1정',
            'frequency': '1일 1회',
            'time': '12:00',
          },
        ],
        'meta': {
          'phone': phone,
          'source': 'link26-bff-dart-stub',
          'note':
              '데모 JSON입니다. 본인 처방·투약은 CODEF 계정·상품 경로·connectedId 등 BFF 실연동이 필요합니다.',
        },
      });
      return;
    }

    request.response.statusCode = 404;
    request.response.headers.contentType = ContentType.text;
    request.response.write('Not found');
    await request.response.close();
  } catch (e, st) {
    // ignore: avoid_print
    print('BFF error: $e\n$st');
    try {
      request.response.statusCode = 500;
      await request.response.close();
    } catch (_) {}
  }
}

Future<void> _json(HttpRequest request, int status, Object body) async {
  request.response.statusCode = status;
  request.response.headers.add('Content-Type', 'application/json; charset=utf-8');
  request.response.headers.add('X-Link26-Bff', 'dart');
  request.response.write(jsonEncode(body));
  await request.response.close();
}

Future<String> _readBody(HttpRequest request) async {
  final chunks = <int>[];
  await for (final chunk in request) {
    chunks.addAll(chunk);
  }
  return utf8.decode(chunks);
}

/// [targetUrl] 로 동일 본문을 POST 하고, 응답 상태·본문을 그대로 클라이언트에 전달합니다.
Future<void> _proxyPost(
  HttpRequest request,
  String targetUrl,
  String bodyStr,
) async {
  Uri uri;
  try {
    uri = Uri.parse(targetUrl);
  } catch (e) {
    await _json(request, 500, {
      'ok': false,
      'detail': 'NHIS_PROXY_* URL 파싱 실패: $e',
    });
    return;
  }
  if (!uri.hasScheme || uri.host.isEmpty) {
    await _json(request, 500, {
      'ok': false,
      'detail': 'NHIS_PROXY_* URL 에 scheme·호스트가 필요합니다.',
    });
    return;
  }

  final client = HttpClient();
  try {
    final ioReq = await client.postUrl(uri);
    ioReq.headers.contentType = ContentType.json;
    ioReq.headers.set(HttpHeaders.acceptHeader, 'application/json,*/*;q=0.8');
    ioReq.write(bodyStr);
    final ioRes = await ioReq.close().timeout(const Duration(seconds: 60));
    final responseBody = await ioRes.transform(utf8.decoder).join();
    request.response.statusCode = ioRes.statusCode;
    final ct = ioRes.headers.contentType;
    if (ct != null) {
      request.response.headers.contentType = ct;
    } else {
      request.response.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
    }
    request.response.headers.add('X-Link26-Bff', 'dart-proxy');
    request.response.write(responseBody);
    await request.response.close();
  } catch (e, st) {
    // ignore: avoid_print
    print('BFF proxy POST: $e\n$st');
    await _json(request, 502, {'ok': false, 'detail': 'upstream proxy: $e'});
  } finally {
    client.close(force: true);
  }
}

Future<void> _handleEasyDrug(HttpRequest request) async {
  final q = request.uri.queryParameters;
  final itemName = (q['itemName'] ?? '').trim();
  if (itemName.isEmpty) {
    await _json(request, 400, {'ok': false, 'detail': 'itemName required'});
    return;
  }
  final env = loadBffDotEnv();
  var key = bffPublicDataServiceKey(env);
  if (key.isEmpty) {
    await _json(request, 503, {
      'ok': false,
      'detail':
          '공공데이터 serviceKey 가 비어 있습니다. 루트 `.env` 또는 '
          '`assets/env/dotenv`(sync 복사본) 중 하나에 아래 키를 넣고 BFF를 재시작하세요: '
          'PUBLIC_DATA_SERVICE_KEY, DATA_GO_KR_SERVICE_KEY, NHIS_SERVICE_KEY. '
          'BFF는 두 파일을 병합해 읽으며, `.env` 값이 같은 키를 덮어씁니다.',
    });
    return;
  }
  try {
    key = Uri.decodeQueryComponent(key);
  } catch (_) {}

  final uri = Uri.https(
    'apis.data.go.kr',
    // 공공데이터포털 문서 기준 서비스명: DrbEasyDrugInfoService
    '/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList',
    {
      'serviceKey': key,
      'pageNo': q['pageNo'] ?? '1',
      'numOfRows': q['numOfRows'] ?? '20',
      'type': 'json',
      'itemName': itemName,
    },
  );

  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    final res = await req.close();
    final raw = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      await _json(request, 502, {
        'ok': false,
        'detail': '공공데이터 HTTP ${res.statusCode}',
        'body': raw.length > 2000 ? raw.substring(0, 2000) : raw,
      });
      return;
    }
    try {
      final data = jsonDecode(raw);
      await _json(request, 200, {'ok': true, 'data': data});
    } catch (_) {
      await _json(request, 200, {'ok': true, 'raw': raw});
    }
  } finally {
    client.close(force: true);
  }
}
