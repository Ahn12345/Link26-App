// `dart run tool/bff_dotenv_line_scan_self_test.dart` — flutter test 가 SUBST(L:) 잔여로
// 깨질 때 쓰는 초경량 검증.
import 'dart:io';

import 'package:link26_app/tool_support/bff_dotenv_line_scan.dart';

void _expect(bool ok, String msg) {
  if (!ok) {
    stderr.writeln('FAIL: $msg');
    throw StateError(msg);
  }
}

void main() {
  _expect(
    BffDotenvLineScan.stripUtf8Bom('\uFEFFTILKO_API_KEY=x') == 'TILKO_API_KEY=x',
    'BOM strip',
  );
  _expect(
    BffDotenvLineScan.scanTilkoApiKeyLineByLine('TILKO_API_KEY=abc') == 'abc',
    'simple key',
  );
  _expect(
    BffDotenvLineScan.scanTilkoApiKeyLineByLine('TILKO_API_KEY=\nTILKO_API_KEY=z') ==
        'z',
    'skip empty then take value',
  );
  _expect(
    BffDotenvLineScan.scanTilkoApiKeyLineByLine(
          '\uFEFFTILKO_API_KEY=bom',
        ) ==
        'bom',
    'BOM then key',
  );
  // ignore: avoid_print
  print('bff_dotenv_line_scan self-test: OK');
}
