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

  test('tilkoFormatCellphoneHyphen formats mobile', () {
    expect(
      tilkoFormatCellphoneHyphen('01012345678'),
      '010-1234-5678',
    );
  });
}
