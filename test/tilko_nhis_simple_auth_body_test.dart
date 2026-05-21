import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('NHIS simpleauth: all four fields AES encrypted', () {
    final aesKey = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
    final body = tilkoNhisSimpleAuthRequestBody(
      aesKey: aesKey,
      privateAuthTypePlain: '4',
      userName: '홍길동',
      birthDateYmd: '20000101',
      userCellphoneHyphen: '010-1234-5678',
    );

    expect(body.keys, hasLength(4));
    expect(body.containsKey('IdentityNumber'), isFalse);
    for (final k in [
      'PrivateAuthType',
      'UserName',
      'BirthDate',
      'UserCellphoneNumber',
    ]) {
      final v = '${body[k]}';
      expect(tilkoFieldLooksAesEncrypted(v), isTrue, reason: k);
    }
  });

  test('LoginCheck bodies: OAuth then Auth then flat', () {
    final flat = <String, dynamic>{'Token': 'enc'};
    final bodies = tilkoNhisLoginCheckRequestBodies(flat);
    expect(bodies.length, 3);
    expect(bodies[0]['OAuth'], flat);
    expect(bodies[1]['Auth'], flat);
    expect(bodies[2], flat);
  });
}
