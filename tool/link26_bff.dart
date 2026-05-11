// Link26 최소 BFF — Node 없이 `dart run tool/link26_bff.dart` 로 실행.
//
// 포트: 환경변수 PORT 가 있으면 그 포트만 사용.
// 없으면 8787~8796 시도 후, 전부 실패 시 OS 임의 포트(0) 사용 → errno 10048 에도 실행 가능.
//
// Windows PowerShell 고정 포트: $env:PORT="8788"; dart run tool/link26_bff.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  stdout.writeln('  POST /v1/signup  POST /v1/login  GET /v1/medications  GET /health');

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
      stderr.writeln('다른 포트: \$env:PORT=8788 (PowerShell)');
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

Future<void> _handle(HttpRequest request) async {
  try {
    final path = request.uri.path;
    final method = request.method;

    if (method == 'GET' && path == '/health') {
      final env = loadBffDotEnv();
      final probe = await codefHealthProbe(env);
      final codefMedicationsReady = bffMedicationsCodefConfigured(env);
      await _json(request, 200, {
        'ok': true,
        'service': 'link26-bff-dart',
        'codef': probe,
        'medicationsSource':
            codefMedicationsReady ? 'codef' : 'stub',
      });
      return;
    }

    if (method == 'POST' && path == '/v1/signup') {
      await request.drain();
      await _json(request, 200, {
        'ok': true,
        'flow': 'signup',
        'receivedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return;
    }

    if (method == 'POST' && path == '/v1/login') {
      await request.drain();
      await _json(request, 200, {
        'ok': true,
        'flow': 'login',
        'receivedAt': DateTime.now().toUtc().toIso8601String(),
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
