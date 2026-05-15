import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('KAKAO maps to 1', () {
    expect(tilkoPrivateAuthTypePlain('KAKAO'), '1');
    expect(tilkoPrivateAuthTypePlain('kakao'), '1');
  });

  test('PASS maps to 5', () {
    expect(tilkoPrivateAuthTypePlain('PASS'), '5');
  });

  test('numeric passthrough', () {
    expect(tilkoPrivateAuthTypePlain('6'), '6');
  });
}
