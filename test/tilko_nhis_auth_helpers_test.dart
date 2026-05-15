import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';

void main() {
  test('tilkoNhisLoginCheckSucceeded parses Result boolean', () {
    expect(tilkoNhisLoginCheckSucceeded({'Result': true}), isTrue);
    expect(tilkoNhisLoginCheckSucceeded({'Result': false}), isFalse);
    expect(tilkoNhisLoginCheckSucceeded({'Result': 'true'}), isTrue);
    expect(tilkoNhisLoginCheckSucceeded({'Result': 'false'}), isFalse);
  });

  test('tilkoNhisLiftNestedSession merges ResultData tokens', () {
    final lifted = tilkoNhisLiftNestedSession({
      'ErrorCode': 0,
      'ResultData': {
        'Token': 't1',
        'CxId': 'c1',
        'TxId': 'x1',
        'ReqTxId': 'r1',
      },
    });
    expect(tilkoNhisAuthTokensComplete(lifted), isTrue);
  });

  test('tilkoNhisSimpleAuthIndicatesError when ErrorCode not zero', () {
    expect(
      tilkoNhisSimpleAuthIndicatesError({
        'ErrorCode': 0,
        'ResultData': {
          'Token': 't1',
          'CxId': 'c1',
          'TxId': 'x1',
          'ReqTxId': 'r1',
        },
      }),
      isFalse,
    );
    expect(
      tilkoNhisSimpleAuthIndicatesError({'ErrorCode': 12001}),
      isTrue,
    );
  });

  test('tilkoNhisSimpleAuthIndicatesError when Message says value not found', () {
    expect(
      tilkoNhisSimpleAuthIndicatesError({
        'ErrorCode': 0,
        'Message': "요청한 값 'abc=='을(를) 찾을 수 없습니다.",
      }),
      isTrue,
    );
  });

  test('tilkoUserFacingMessageKo hides encrypted value-not-found', () {
    const raw = "요청한 값 '11G1+Wo3AZ2FvwzmbvrMUw=='을(를) 찾을 수 없습니다.";
    final friendly = tilkoUserFacingMessageKo(raw);
    expect(friendly, isNot(contains('11G1+')));
    expect(friendly, contains('카카오'));
  });

  test('tilkoFriendlyHintFromLifted uses Message when tokens empty', () {
    final hint = tilkoFriendlyHintFromLifted({
      'ErrorCode': 0,
      'Message': "요청한 값 'abc=='을(를) 찾을 수 없습니다.",
    });
    expect(hint, isNot(contains('abc==')));
  });

  test('tilkoCoherentBirthYmd prefers RRN when birth mismatches', () {
    expect(
      tilkoCoherentBirthYmd(
        birthDateYmd: '19990101',
        identityNumber: '0405223123456',
      ),
      '20040522',
    );
  });

  test('tilkoPrepareSimpleAuthRequestMap normalizes phone and birth', () {
    final m = tilkoPrepareSimpleAuthRequestMap({
      'UserName': '  안병찬 ',
      'BirthDate': '20040522',
      'UserCellphoneNumber': '01090891562',
      'IdentityNumber': '040522-3123456',
    });
    expect(m['UserName'], '안병찬');
    expect(m['UserCellphoneNumber'], '010-9089-1562');
    expect(m['BirthDate'], '20040522');
    expect(m['IdentityNumber'], '0405223123456');
  });

  test('tilkoFormatCellphoneHyphen formats mobile', () {
    expect(
      tilkoFormatCellphoneHyphen('01012345678'),
      '010-1234-5678',
    );
  });
}
