import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('KAKAO name and numeric candidates', () {
    expect(tilkoPrivateAuthTypeName('KAKAO'), 'KAKAO');
    expect(tilkoPrivateAuthTypeNumeric('KAKAO'), '1');
    expect(
      tilkoPrivateAuthTypeCandidates('KAKAO'),
      ['1', 'KAKAO'],
    );
  });

  test('PASS maps to 5', () {
    expect(tilkoPrivateAuthTypeName('PASS'), 'PASS');
    expect(tilkoPrivateAuthTypeNumeric('PASS'), '5');
  });

  test('wire plain keeps numeric 1 for Tilko AES', () {
    expect(tilkoPrivateAuthTypeWirePlain('1'), '1');
    expect(tilkoPrivateAuthTypeWirePlain('KAKAO'), 'KAKAO');
    expect(tilkoPrivateAuthTypeWirePlain('KAKAO'), isNot('1'));
  });
}
