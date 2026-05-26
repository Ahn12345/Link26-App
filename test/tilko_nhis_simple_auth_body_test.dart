import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  final aesKey = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));

  test('NHIS simpleauth: PrivateAuthType plain, other three AES', () {
    final body = tilkoNhisSimpleAuthRequestBody(
      aesKey: aesKey,
      privateAuthTypePlain: '4',
      userName: '홍길동',
      birthDateYmd: '20000101',
      userCellphoneHyphen: '010-1234-5678',
    );

    expect(body['PrivateAuthType'], '4');
    expect(tilkoFieldLooksAesEncrypted('${body['PrivateAuthType']}'), isFalse);
    for (final k in ['UserName', 'BirthDate', 'UserCellphoneNumber']) {
      expect(tilkoFieldLooksAesEncrypted('${body[k]}'), isTrue, reason: k);
    }
  });

  test('LoginCheck Auth: three AES, tokens and PrivateAuthType plain', () {
    final auth = tilkoNhisLoginCheckAuthFields(
      aesKey: aesKey,
      birthDateYmd: '20040522',
      userName: '테스트',
      userCellphoneHyphen: '010-1234-5678',
      privateAuthTypePlain: '4',
      token: 'tok-plain',
      cxId: 'cx-plain',
      txId: 'tx-plain',
      reqTxId: 'req-plain',
    );

    expect(auth['PrivateAuthType'], '4');
    expect(auth['Token'], 'tok-plain');
    expect(tilkoFieldLooksAesEncrypted('${auth['BirthDate']}'), isTrue);
    expect(tilkoFieldLooksAesEncrypted('${auth['Token']}'), isFalse);

    final bodies = tilkoNhisLoginCheckRequestBodies(auth);
    expect(bodies.length, 1);
    expect(bodies[0]['Auth'], auth);
  });
}
