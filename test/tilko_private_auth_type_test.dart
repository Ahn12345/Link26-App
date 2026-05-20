import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('KAKAO name and numeric candidates', () {
    expect(tilkoPrivateAuthTypeName('KAKAO'), 'KAKAO');
    expect(tilkoPrivateAuthTypeNumeric('KAKAO'), '0');
    expect(
      tilkoPrivateAuthTypeCandidates('KAKAO'),
      ['0', 'KAKAO'],
    );
  });

  test('PASS maps to 4 (5 is Shinhan per Tilko)', () {
    expect(tilkoPrivateAuthTypeName('PASS'), 'PASS');
    expect(tilkoPrivateAuthTypeNumeric('PASS'), '4');
    expect(tilkoPrivateAuthTypeName('5'), 'SHINHAN');
    expect(tilkoPrivateAuthTypeWirePlain('PASS'), '4');
  });

  test('wire plain uses Tilko numeric codes for NHIS channels', () {
    expect(tilkoPrivateAuthTypeWirePlain('1'), '1');
    expect(tilkoPrivateAuthTypeWirePlain('KAKAO'), '0');
    expect(tilkoPrivateAuthTypeWirePlain('PASS'), '4');
  });
}
