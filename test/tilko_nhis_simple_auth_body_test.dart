import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('NHIS simpleauth: PrivateAuthType plain, other fields AES', () {
    final aesKey = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
    final body = tilkoNhisSimpleAuthRequestBody(
      aesKey: aesKey,
      privateAuthTypePlain: 'PASS',
      userName: '홍길동',
      birthDateYmd: '20000101',
      userCellphoneHyphen: '010-1234-5678',
    );

    expect(body.keys, hasLength(4));
    expect(body.containsKey('IdentityNumber'), isFalse);
    expect(body['PrivateAuthType'], 'PASS');
    expect(tilkoFieldLooksAesEncrypted('${body['PrivateAuthType']}'), isFalse);

    for (final k in ['UserName', 'BirthDate', 'UserCellphoneNumber']) {
      final v = '${body[k]}';
      expect(v, isNot(equals('홍길동')));
      expect(tilkoFieldLooksAesEncrypted(v), isTrue, reason: k);
    }
  });
}
