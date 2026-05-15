import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('empty plain text does not throw (logincheck before tokens)', () {
    final aesKey = Uint8List(16);
    expect(() => tilkoAesEncryptFieldOrEmpty(aesKey, ''), returnsNormally);
    expect(tilkoAesEncryptFieldOrEmpty(aesKey, ''), '');
    expect(tilkoAesEncryptFieldOrEmpty(aesKey, '   '), '');
  });

  test('non-empty plain text encrypts', () {
    final aesKey = Uint8List(16);
    final out = tilkoAesEncryptFieldOrEmpty(aesKey, 'KAKAO');
    expect(out, isNotEmpty);
  });
}
