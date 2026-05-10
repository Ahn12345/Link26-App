// Link26 최소 BFF — Node 없이 `dart run tool/link26_bff.dart` 로 실행.
// 기본 포트 8787 (환경변수 PORT 로 변경 가능, Windows: set PORT=9999)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8787') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print('link26-bff (Dart) http://0.0.0.0:$port');
  // ignore: avoid_print
  print('  POST /v1/signup  POST /v1/login  GET /v1/medications  GET /health');

  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  try {
    final path = request.uri.path;
    final method = request.method;

    if (method == 'GET' && path == '/health') {
      await _json(request, 200, {'ok': true, 'service': 'link26-bff-dart'});
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
      final phone = request.uri.queryParameters['phone'] ?? '';
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
        'meta': {'phone': phone, 'source': 'link26-bff-dart'},
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

