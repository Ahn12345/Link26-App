import 'package:test/test.dart';
import 'package:link26_app/tool_support/bff_dotenv_line_scan.dart';

void main() {
  group('BffDotenvLineScan.stripUtf8Bom', () {
    test('removes leading UTF-8 BOM', () {
      expect(BffDotenvLineScan.stripUtf8Bom('\uFEFFTILKO_API_KEY=x'), 'TILKO_API_KEY=x');
    });
    test('passes through without BOM', () {
      expect(BffDotenvLineScan.stripUtf8Bom('NHIS_BASE_URL=http://1.2.3.4:5'),
          'NHIS_BASE_URL=http://1.2.3.4:5');
    });
  });

  group('BffDotenvLineScan.scanTilkoApiKeyLineByLine', () {
    test('parses simple assignment', () {
      expect(
        BffDotenvLineScan.scanTilkoApiKeyLineByLine('TILKO_API_KEY=abc123def456'),
        'abc123def456',
      );
    });
    test('strips double quotes', () {
      expect(
        BffDotenvLineScan.scanTilkoApiKeyLineByLine('TILKO_API_KEY="quotedkey"'),
        'quotedkey',
      );
    });
    test('ignores comments and empty lines', () {
      const raw = '''
# comment
TILKO_API_KEY=

TILKO_API_KEY=realkey
''';
      expect(BffDotenvLineScan.scanTilkoApiKeyLineByLine(raw), 'realkey');
    });
    test('takes first non-empty when multiple lines', () {
      const raw = 'TILKO_API_KEY=first\nTILKO_API_KEY=second';
      expect(BffDotenvLineScan.scanTilkoApiKeyLineByLine(raw), 'first');
    });
    test('strips inline hash comment after value', () {
      expect(
        BffDotenvLineScan.scanTilkoApiKeyLineByLine('TILKO_API_KEY=mykey # tilko'),
        'mykey',
      );
    });
    test('returns null when only empty placeholder', () {
      expect(BffDotenvLineScan.scanTilkoApiKeyLineByLine('TILKO_API_KEY=\n#x'), isNull);
    });
    test('works with BOM at file start', () {
      expect(
        BffDotenvLineScan.scanTilkoApiKeyLineByLine(
          '\uFEFFOTHER=1\nTILKO_API_KEY=bomworks',
        ),
        'bomworks',
      );
    });
  });
}
