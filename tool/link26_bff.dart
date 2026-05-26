// Link26 최소 BFF — Node 없이 `dart run tool/link26_bff.dart` 로 실행.
//
// 제품 흐름(의도): 로그인/가입 후 틸코 국민건강보험공단 간편인증 → NHIS 진료 및 투약 정보 → 본인 복약.
// 이 Dart BFF는 틸코·공공 e약은요 등을 한 PC에서 돕습니다. 복약 실데이터는 틸코 NHIS 간편인증 플로우만 사용합니다.
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
import 'package:link26_app/integrations/tilko/tilko_pass_uri_extract.dart';
import 'package:link26_app/integrations/tilko/tilko_response_meta.dart';

import 'link26_bff_codef.dart';
import 'link26_bff_lan_beacon.dart';

String _bffYmd(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

Future<void> main() async {
  final server = await _bindServer();
  final port = server.port;
  startLink26BffLanBeacon(port);

  // ignore: avoid_print
  stdout.writeln('');
  // ignore: avoid_print
  stdout.writeln('>>> link26-bff (Dart) 실제 포트: $port <<<');
  // ignore: avoid_print
  stdout.writeln('    http://127.0.0.1:$port/health');
  // ignore: avoid_print
  stdout.writeln('    에뮬용 .env: NHIS_BASE_URL=http://10.0.2.2:$port');
  // ignore: avoid_print
  stdout.writeln('    LAN 자동발견: UDP $kLink26BffLanUdpPort 포트로 BFF 주소 비콘(3초마다)');
  await _printLanBffHints(port);
  // ignore: avoid_print
  stdout.writeln('');
  // ignore: avoid_print
  stdout.writeln(
    '  POST /v1/signup  POST /v1/login  GET /v1/medications(스텁)  GET /health\n'
    '  GET /v1/public/easy-drug  POST /v1/tilko/hira-simple-auth  POST /v1/flow/tilko-hira-medications',
  );
  final bootEnv = loadBffDotEnv();
  logBffDotEnvBootstrap(bootEnv);
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

/// 폰과 같은 Wi-Fi·LAN에 쓰기 적절한 사설 IPv4만(VPN 등 공인·비사설 잡 주소 제외).
bool _isPrivateLanIpv4(InternetAddress a) {
  if (a.type != InternetAddressType.IPv4 || a.isLoopback) return false;
  final parts = a.address.split('.');
  if (parts.length != 4) return false;
  final o1 = int.tryParse(parts[0]);
  final o2 = int.tryParse(parts[1]);
  if (o1 == null || o2 == null) return false;
  if (o1 == 10) return true;
  if (o1 == 172 && o2 >= 16 && o2 <= 31) return true;
  if (o1 == 192 && o2 == 168) return true;
  return false;
}

/// 폰과 같은 Wi-Fi·LAN 대역의 IPv4만 안내(이더넷 vs Wi-Fi 혼동 방지).
Future<void> _printLanBffHints(int port) async {
  if (port <= 0 || port > 65535) return;
  try {
    final ifs = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    final urls = <String>{};
    for (final ni in ifs) {
      for (final a in ni.addresses) {
        if (!_isPrivateLanIpv4(a)) continue;
        urls.add('http://${a.address}:$port');
      }
    }
    if (urls.isEmpty) return;
    final list = urls.toList()..sort();
    // ignore: avoid_print
    stdout.writeln('');
    // ignore: avoid_print
    stdout.writeln(
      '    실제 안드로이드 폰: 아래 중 폰과 같은 대역(같은 공유기·LAN) 하나를 '
      'assets/env/dotenv 의 NHIS_BASE_URL 로 넣고 앱을 다시 빌드하세요.',
    );
    for (final u in list) {
      // ignore: avoid_print
      stdout.writeln('      NHIS_BASE_URL=$u');
    }
    // ignore: avoid_print
    stdout.writeln(
      '    (Wi-Fi와 이더넷 IP가 다르면, 폰이 Wi-Fi만 쓸 때는 Wi-Fi 쪽 주소를 써야 합니다.)',
    );
  } catch (_) {
    // ignore: avoid_print
    stdout.writeln(
      '    (LAN IPv4 자동 나열 실패 — PC에서 ipconfig 로 IPv4 확인 후 '
      'NHIS_BASE_URL=http://<IPv4>:$port)',
    );
  }
}

void _printEnvReadinessSummary(Map<String, String> env) {
  final pub = bffPublicDataConfigured(env);
  final tilko = (env['TILKO_API_KEY'] ?? '').trim().isNotEmpty;
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
    '    복약 실데이터: CODEF 미사용 — POST /v1/flow/tilko-hira-medications (틸코 NHIS)',
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
    if (!(method == 'GET' && path == '/health')) {
      final peer = request.connectionInfo?.remoteAddress.address ?? '?';
      // ignore: avoid_print
      print('BFF ← $method $path (from $peer)');
    }

    if (method == 'GET' && path == '/health') {
      final env = loadBffDotEnv();
      await _json(request, 200, {
        'ok': true,
        'service': 'link26-bff-dart',
        'tilko': {
          'configured': (env['TILKO_API_KEY'] ?? '').trim().isNotEmpty,
        },
        'publicData': {
          'configured': bffPublicDataConfigured(env),
          'serviceKeyFrom': _publicDataKeySourceForHealth(env) ?? 'none',
        },
        'medicationsSource': 'tilko_nhis_flow',
        'medicationsNote':
            '실복약 데이터는 POST /v1/flow/tilko-hira-medications 입니다. '
            'GET /v1/medications 는 데모 스텁만 반환합니다.',
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
        var detail = '$e';
        if (e is StateError) {
          final m = e.toString();
          const p = 'Bad state: ';
          if (m.startsWith(p)) detail = m.substring(p.length);
        }
        await _json(request, 200, {
          'ok': false,
          'detail': detail,
          'hint_ko':
              '틸코 간편인증 요청에 실패했습니다. 이 PC에서 띄운 Dart BFF의 `.env`에 '
              'TILKO_API_KEY·TILKO_API_HOST(예: https://dev.tilko.net)가 맞는지 확인하세요.',
        });
      }
      return;
    }

    if (method == 'POST' &&
        (path == '/v1/flow/tilko-hira-medications' ||
            path == '/v1/flow/tilko-codef-treatment')) {
      final bodyStr = await _readBody(request);
      final env = loadBffDotEnv();
      try {
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        final phase = (map['phase'] as String?)?.trim().toLowerCase() ?? 'full';
        var tilkoMap = tilkoPrepareSimpleAuthRequestMap(
          map['tilko'] as Map<String, dynamic>? ?? map,
        );
        // ignore: avoid_print
        final envPat =
            (env['TILKO_PRIVATE_AUTH_TYPE'] ?? 'PASS').trim();
        final patRaw = envPat.isNotEmpty
            ? envPat
            : '${tilkoMap['PrivateAuthType'] ?? tilkoMap['privateAuthType'] ?? 'PASS'}'
                .trim();
        final patForFlow = patRaw.isEmpty ? 'PASS' : patRaw;
        final singleShotAuth = tilkoIsSingleShotAuthChannel(patForFlow);
        // ignore: avoid_print
        print(
          'BFF flow tilko-hira-medications: 요청 수신 '
          '(UserName=${tilkoMap['UserName']}, '
          '간편인증=${tilkoSimpleAuthChannelLabelKo(patForFlow)}, '
          'BirthDate=${tilkoMap['BirthDate']}, '
          'rrn13=${tilkoIdentityDigits13('${tilkoMap['IdentityNumber'] ?? ''}').length == 13})',
        );
        // flow_extras: 앱이 BFF로 넘기는 부가 필드(connectedId 등). 현재 NHIS 플로우 본문에서는 미사용.
        final tilkoClient = TilkoHiraSimpleAuthClient.fromBffEnv(env);
        var patCandidates = tilkoPrivateAuthTypeCandidates(patForFlow);
        var phoneCandidates = tilkoCellphoneWireCandidates(
          '${tilkoMap['UserCellphoneNumber'] ?? ''}',
        );
        var authChannel = 'NHIS';
        Map<String, dynamic>? tilkoRes;
        Map<String, dynamic>? tilkoResLifted;
        Map<String, dynamic>? lastNhisLifted;
        Map<String, dynamic>? lastHiraLifted;
        var usedPat = patCandidates.isNotEmpty ? patCandidates.first : '1';
        var broke = false;
        var simpleAuthAttemptsLabel = '1회';

        if (phase == 'continue') {
          final liftedRaw = map['tilko_simple_auth'];
          if (liftedRaw is! Map) {
            await _json(request, 200, {
              'ok': false,
              'detail': 'tilko_simple_auth 세션이 없습니다.',
              'hint_ko': '먼저 간편인증 요청(phase=start)을 한 뒤 다시 시도하세요.',
            });
            return;
          }
          tilkoResLifted = Map<String, dynamic>.from(
            liftedRaw.map((k, v) => MapEntry('$k', v)),
          );
          tilkoRes = Map<String, dynamic>.from(tilkoResLifted);
          authChannel =
              (map['auth_channel'] as String?)?.trim().isNotEmpty == true
                  ? '${map['auth_channel']}'.trim()
                  : 'NHIS';
          broke = true;
          // ignore: avoid_print
          print(
            'BFF flow continue: logincheck 폴링 — '
            '${tilkoNhisTokenPresenceSummary(tilkoResLifted)}',
          );
        }

        void logSimpleAuthFail(
          String channel,
          String patTry,
          String cellWire,
          bool withIdentity,
          Map<String, dynamic> lifted,
        ) {
          final nhisMsg = tilkoFindPlainString(lifted, 'Message');
          final nhisTarget = tilkoFindPlainString(lifted, 'TargetCode');
          final apiTxKey = tilkoFindPlainString(lifted, 'ApiTxKey');
          final errLog = tilkoFindPlainString(lifted, 'ErrorLog');
          final status = tilkoFindPlainString(lifted, 'Status');
          // ignore: avoid_print
          print(
            'BFF ① $channel simpleauth(PrivateAuthType=$patTry, '
            'wire=${tilkoPrivateAuthTypeWirePlain(patTry)}, phone=$cellWire, '
            'identity=$withIdentity) '
            '실패 Status=${status ?? '-'} Message=${nhisMsg ?? '-'} '
            'TargetCode=${nhisTarget ?? '-'} ApiTxKey=${apiTxKey ?? '-'} '
            'ErrorLog=${errLog ?? '-'}',
          );
        }

        if (!broke && singleShotAuth) {
          final id13 = tilkoIdentityDigits13(
            '${tilkoMap['IdentityNumber'] ?? ''}',
          );
          final cellWire = phoneCandidates.isNotEmpty
              ? phoneCandidates.first
              : tilkoFormatCellphoneHyphen(
                  '${tilkoMap['UserCellphoneNumber'] ?? ''}',
                );
          final passChannel =
              tilkoPrivateAuthTypeName(patForFlow) == 'PASS';
          // PASS·NHIS: PrivateAuthType 평문 `4`=통신사PASS (`5`=신한, 문자열 PASS 거절).
          final kakaoAttempts = passChannel
              ? <({String channel, String pat, bool identity})>[
                  (channel: 'NHIS', pat: '4', identity: false),
                ]
              : <({String channel, String pat, bool identity})>[
                  (
                    channel: 'NHIS',
                    pat: patCandidates.isNotEmpty
                        ? patCandidates.first
                        : '1',
                    identity: id13.length == 13,
                  ),
                ];
          simpleAuthAttemptsLabel = '${kakaoAttempts.length}회';
          for (final att in kakaoAttempts) {
            usedPat = att.pat;
            authChannel = att.channel;
            final reqMap = Map<String, dynamic>.from(tilkoMap)
              ..['PrivateAuthType'] = att.pat
              ..['UserCellphoneNumber'] = cellWire;
            // ignore: avoid_print
            print(
              'BFF ① simpleauthrequest (${att.channel}, identity=${att.identity}) — '
              '${tilkoSimpleAuthRequestLogLine(reqMap)}',
            );
            if (att.channel == 'NHIS') {
              tilkoRes = await tilkoClient.requestNhisSimpleAuthFromJsonMap(
                reqMap,
                includeIdentityNumber: att.identity,
              );
            } else {
              tilkoRes = await tilkoClient.requestFromJsonMap(reqMap);
            }
            tilkoResLifted = tilkoNhisLiftNestedSession(tilkoRes);
            if (att.channel == 'NHIS') {
              lastNhisLifted = tilkoResLifted;
            } else {
              lastHiraLifted = tilkoResLifted;
            }
            if (tilkoRes['http_status'] == null &&
                !tilkoNhisSimpleAuthIndicatesError(tilkoResLifted)) {
              broke = true;
              break;
            }
            logSimpleAuthFail(
              att.channel,
              att.pat,
              cellWire,
              att.identity,
              tilkoResLifted,
            );
          }
        } else if (!broke) {
          outer:
          for (final patTry in patCandidates) {
            for (final cellWire in phoneCandidates) {
              usedPat = patTry;
              final reqMap = Map<String, dynamic>.from(tilkoMap)
                ..['PrivateAuthType'] = patTry
                ..['UserCellphoneNumber'] = cellWire;
              // ignore: avoid_print
              print(
                'BFF ① simpleauthrequest 요청 필드 — '
                '${tilkoSimpleAuthRequestLogLine(reqMap)}',
              );

              authChannel = 'NHIS';
              tilkoRes = await tilkoClient.requestNhisSimpleAuthFromJsonMap(
                reqMap,
                includeIdentityNumber: tilkoIdentityDigits13(
                      '${tilkoMap['IdentityNumber'] ?? ''}',
                    ).length ==
                    13,
              );
              tilkoResLifted = tilkoNhisLiftNestedSession(tilkoRes);
              lastNhisLifted = tilkoResLifted;
              if (tilkoRes['http_status'] == null &&
                  !tilkoNhisSimpleAuthIndicatesError(tilkoResLifted)) {
                broke = true;
                break outer;
              }
              final nhisMsg = tilkoFindPlainString(tilkoResLifted, 'Message');
              logSimpleAuthFail(
                'NHIS',
                patTry,
                cellWire,
                tilkoIdentityDigits13(
                      '${tilkoMap['IdentityNumber'] ?? ''}',
                    ).length ==
                    13,
                tilkoResLifted,
              );

              authChannel = 'HIRA';
              tilkoRes = await tilkoClient.requestFromJsonMap(reqMap);
              tilkoResLifted = tilkoNhisLiftNestedSession(tilkoRes);
              lastHiraLifted = tilkoResLifted;
              if (tilkoRes['http_status'] == null &&
                  !tilkoNhisSimpleAuthIndicatesError(tilkoResLifted)) {
                broke = true;
                break outer;
              }
              final hiraMsg = tilkoFindPlainString(tilkoResLifted, 'Message');
              if (!tilkoSimpleAuthMessageRetryable(nhisMsg) &&
                  !tilkoSimpleAuthMessageRetryable(hiraMsg)) {
                broke = true;
                break outer;
              }
              // ignore: avoid_print
              print(
                'BFF ① HIRA simpleauth(PrivateAuthType=$patTry) — '
                '다음 후보 시도',
              );
            }
          }
        }
        if (!broke) {
          // ignore: avoid_print
          print(
            'BFF ① simpleauth 실패(${tilkoSimpleAuthChannelLabelKo(patForFlow)} '
            '${singleShotAuth ? simpleAuthAttemptsLabel : '후보 소진'})',
          );
        }

        tilkoRes ??= <String, dynamic>{};
        tilkoResLifted ??= <String, dynamic>{};
        // ignore: avoid_print
        print('BFF ① simpleauth 최종 PrivateAuthType=$usedPat channel=$authChannel');
        if (tilkoRes['http_status'] != null) {
          // ignore: avoid_print
          print('BFF ① simpleauthrequest: HTTP ${tilkoRes['http_status']}');
          await _json(request, 200, {
            'ok': false,
            'detail': '틸코 간편인증(simpleauthrequest) HTTP 오류 ($authChannel)',
            'hint_ko':
                'TILKO_API_KEY·TILKO_API_HOST(데모: https://dev.tilko.net)와 요청 필드를 확인하세요.',
            'tilko': tilkoRes,
          });
          return;
        }

        final rd = tilkoResLifted['ResultData'];
        final rdKeys = rd is Map
            ? rd.keys.join(',')
            : (rd == null ? 'null' : rd.runtimeType.toString());
        final targetMsg = tilkoFindPlainString(tilkoResLifted, 'TargetMessage');
        final pointBal = tilkoFindPlainString(tilkoResLifted, 'PointBalance');
        // ignore: avoid_print
        print(
          'BFF ① $authChannel simpleauthrequest — '
          '${tilkoNhisTokenPresenceSummary(tilkoResLifted)} '
          'ErrorCode=${tilkoFindPlainString(tilkoResLifted, 'ErrorCode') ?? '-'} '
          'Message=${tilkoFindPlainString(tilkoResLifted, 'Message') ?? '-'} '
          'TargetMessage=${targetMsg ?? '-'} '
          'PointBalance=${pointBal ?? '-'} '
          'topKeys=${tilkoResLifted.keys.join(',')} ResultData=($rdKeys)',
        );
        if (tilkoNhisSimpleAuthIndicatesError(tilkoResLifted)) {
          final hint = tilkoBestSimpleAuthHintKo(
            nhisLifted: lastNhisLifted,
            hiraLifted: lastHiraLifted,
            privateAuthType: patForFlow,
          );
          final nhisMsg =
              tilkoFindPlainString(tilkoResLifted, 'Message') ?? '';
          await _json(request, 200, {
            'ok': false,
            'detail':
                '틸코 simpleauthrequest 오류 ($authChannel, ErrorCode=${tilkoFindPlainString(tilkoResLifted, 'ErrorCode')})',
            'hint_ko': hint,
            'meta': {
              'simple_auth_mismatch': nhisMsg.contains('찾을 수 없'),
              'api_tx_key': tilkoFindPlainString(tilkoResLifted, 'ApiTxKey'),
            },
            'tilko': tilkoRes,
          });
          return;
        }
        if (phase == 'start') {
          final passUris =
              TilkoPassUriExtract.extractLaunchUrisFromTilko(tilkoResLifted);
          // ignore: avoid_print
          final apiTx = tilkoFindPlainString(tilkoResLifted, 'ApiTxKey');
          final targetMsg = tilkoFindPlainString(tilkoResLifted, 'TargetMessage');
          // ignore: avoid_print
          print(
            'BFF ① phase=start — PASS 실행 URL ${passUris.length}건, '
            '${tilkoNhisTokenPresenceSummary(tilkoResLifted)} '
            'ApiTxKey=${apiTx ?? '-'} TargetMessage=${targetMsg ?? '-'}',
          );
          if (passUris.isEmpty) {
            // ignore: avoid_print
            print(
              'BFF ① PASS URL 없음 — 틸코는 성공이나 통신사 푸시·딥링크가 없을 수 있습니다. '
              '① 문자(SMS) OTP ② PASS 「나의 인증내역」 ③ 가입 통신사 PASS 앱(SKT/KT/LGU) ④ '
              '이름·010 번호·생년월일이 PASS 가입 정보와 동일한지 확인.',
            );
          }
          await _json(request, 200, {
            'ok': true,
            'phase': 'await_user_auth',
            'pass_launch_uris': passUris,
            'tilko_simple_auth': tilkoResLifted,
            'auth_channel': authChannel,
            'hint_ko': passUris.isEmpty
                ? '틸코 요청은 성공했습니다. PASS 홈만 보이면: '
                    '① 휴대폰 **문자(SMS)** 에 인증번호·링크가 왔는지 확인 '
                    '② PASS **나의 인증내역**·**알림(종)** 확인 '
                    '③ SKT·KT·LGU **본인 통신사** PASS 앱인지 확인 '
                    '④ 이름·010-9089-1562·생년월일이 PASS 가입 정보와 같은지 확인'
                : 'PASS 앱 인증 화면에서 승인해 주세요.',
          });
          return;
        }
        final loginPaths = authChannel == 'HIRA'
            ? tilkoNhisLoginCheckPathCandidates(includeHiraV1: true)
            : tilkoNhisLoginCheckPathCandidates();
        final tilkoAuth = await tilkoClient.waitForNhisAuthForTreatmentInjection(
          tilkoRequestMap: tilkoMap,
          initialSimpleAuthResponse: tilkoRes,
          logPollProgress: true,
          maxAttempts: kTilkoNhisLoginCheckMaxAttempts,
          interval: kTilkoNhisLoginCheckPollInterval,
          loginCheckPathCandidates: loginPaths,
        );
        final pollErr = tilkoAuth['_link26_poll_error'];
        final pollFailed = pollErr is String && pollErr.trim().isNotEmpty;
        final authReady = tilkoNhisSimpleAuthReadyForTreatmentFetch(tilkoAuth);
        if (!authReady) {
          // ignore: avoid_print
          print(
            'BFF ② logincheck 실패 — ${tilkoNhisTokenPresenceSummary(tilkoAuth)}'
            '${pollFailed ? ' (PASS 승인 미완료·Result=대기)' : ''}',
          );
          final errBit = pollErr is String && pollErr.trim().isNotEmpty
              ? ' ($pollErr)'
              : '';
          final lastLc = tilkoAuth['_link26_last_logincheck'];
          Map<String, dynamic>? lastLcBody;
          if (lastLc is Map) {
            lastLcBody = lastLc['body'] is Map
                ? Map<String, dynamic>.from(
                    (lastLc['body'] as Map).map(
                      (k, v) => MapEntry('$k', v),
                    ),
                  )
                : Map<String, dynamic>.from(
                    lastLc.map((k, v) => MapEntry('$k', v)),
                  );
          }
          final pollHint = pollErr is String &&
                  pollErr.contains('일시적인 장애')
              ? tilkoNhisLoginCheckHintKo(lastLcBody)
              : pollErr is String && pollErr.contains('LoginCheck 오류')
                  ? tilkoNhisLoginCheckHintKo(lastLcBody)
                  : pollErr is String &&
                      pollErr.contains('simpleauthrequest 응답에 CxId')
                  ? '틸코 simpleauthrequest 단계에서 세션 토큰을 받지 못했습니다. '
                      '통신사 PASS(`.env` TILKO_PRIVATE_AUTH_TYPE=PASS) 간편인증으로 '
                      'PASS 앱·문자 인증을 완료했는지 확인하세요. '
                      'TILKO_API_KEY·틸코 상품(NHIS·PASS 간편인증) 권한을 확인하세요.'
                  : tilkoNhisLoginCheckHintKo(lastLcBody) +
                      (errBit.isNotEmpty ? errBit : '');
          await _json(request, 200, {
            'ok': false,
            'detail': 'NHIS 간편인증을 마치지 못했습니다.',
            'hint_ko': pollHint,
            'tilko': tilkoRes,
            'tilko_after_poll': tilkoAuth,
            'meta': {'awaiting_nhis_simple_auth': true},
          });
          return;
        }

        // ignore: avoid_print
        print('BFF ② logincheck OK — ${tilkoNhisTokenPresenceSummary(tilkoAuth)}');
        final end = DateTime.now();
        final start = DateTime(end.year - 3, end.month, end.day);
        Map<String, dynamic>? hiraRes;
        Map<String, dynamic>? nhisRes;
        var items = <Map<String, dynamic>>[];
        var metaSource = 'tilko_hira_my_medications';

        if (authChannel == 'HIRA') {
          try {
            hiraRes = await tilkoClient.requestHiraMyMedicationsSimpleAuth(
              tilkoRequestMap: tilkoMap,
              tilkoAuthResponse: tilkoAuth,
              startDateYyyymmdd: _bffYmd(start),
              endDateYyyymmdd: _bffYmd(end),
            );
            if (hiraRes['http_status'] == null &&
                !tilkoApiIndicatesFailure(hiraRes)) {
              items = bffMapCodefRootToMedicationItems(hiraRes);
            }
          } catch (e) {
            // ignore: avoid_print
            print('BFF flow HIRA 조회: $e');
          }
        }

        if (items.isEmpty) {
          nhisRes =
              await tilkoClient.requestNhisRetrieveTreatmentInjectionInformationPerson(
            tilkoRequestMap: tilkoMap,
            tilkoAuthResponse: tilkoAuth,
          );
          if (nhisRes['http_status'] != null) {
            final inner = nhisRes['body'];
            await _json(request, 200, {
              'ok': false,
              'detail': '틸코 NHIS 진료·투약 정보(간편인증) HTTP 오류',
              'hint_ko':
                  '공단 간편인증이 완료된 뒤 호출했는지, '
                  '문서(https://apidemo.tilko.net … NhisSimpleAuth-RetrieveTreatmentInjectionInformationPerson)와 대조하세요.',
              'tilko': tilkoAuth,
              'nhis_treatment_injection':
                  inner is Map<String, dynamic> ? inner : nhisRes,
            });
            return;
          }

          if (tilkoApiIndicatesFailure(nhisRes)) {
            final st = tilkoApiStatusFields(nhisRes);
            await _json(request, 200, {
              'ok': false,
              'detail':
                  'NHIS 진료·투약 조회 실패: ${st['code'] ?? ''} ${st['message'] ?? ''}'.trim(),
              'hint_ko':
                  '틸코 응답 Status를 확인하세요. 간편인증이 완료되지 않았거나 조회 기간에 이력이 없을 수 있습니다.',
              'tilko': tilkoAuth,
              'nhis_treatment_injection': nhisRes,
            });
            return;
          }

          items = bffMapCodefRootToMedicationItems(nhisRes);
          metaSource = 'tilko_nhis_simpleauth_treatment_injection';
        }

        if (items.isEmpty && hiraRes == null) {
          try {
            hiraRes = await tilkoClient.requestHiraMyMedicationsSimpleAuth(
              tilkoRequestMap: tilkoMap,
              tilkoAuthResponse: tilkoAuth,
              startDateYyyymmdd: _bffYmd(start),
              endDateYyyymmdd: _bffYmd(end),
            );
            if (hiraRes['http_status'] == null &&
                !tilkoApiIndicatesFailure(hiraRes)) {
              final hiraItems = bffMapCodefRootToMedicationItems(hiraRes);
              if (hiraItems.isNotEmpty) {
                items = hiraItems;
                metaSource = 'tilko_hira_my_medications';
                // ignore: avoid_print
                print(
                  'BFF flow: NHIS 0건 → HIRA hiraa050300000100 ${items.length}건',
                );
              }
            }
          } catch (e) {
            // ignore: avoid_print
            print('BFF flow HIRA fallback: $e');
          }
        }
        final emptyParsed = items.isEmpty;
        final st = tilkoApiStatusFields(hiraRes ?? nhisRes ?? tilkoAuth);
        // ignore: avoid_print
        print('BFF flow tilko-hira-medications: ok items=${items.length}');
        await _json(request, 200, {
          'ok': true,
          'tilko': tilkoAuth,
          'nhis_treatment_injection': nhisRes,
          'hira_medications': hiraRes ?? nhisRes,
          'items': items,
          'meta': {
            'source': metaSource,
            'codefResultCode': st['code'],
            'codefResultMessage': st['message'],
            if (emptyParsed)
              'note':
                  'NHIS·심평원(HIRA) 응답은 수신했으나 앱이 인식한 복약 행이 0건입니다. '
                  '조회 기간 내 처방이 없거나 JSON 필드명이 바뀐 경우일 수 있습니다.',
          },
        });
      } catch (e, st) {
        // ignore: avoid_print
        print('BFF flow tilko-hira: $e\n$st');
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
              '데모 JSON입니다. 본인 처방·투약은 POST /v1/flow/tilko-hira-medications '
              '(틸코 NHIS 간편인증)으로만 조회합니다. '
              '이전 CODEF 건보 GET 연동은 BFF에서 제거되었습니다.',
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
