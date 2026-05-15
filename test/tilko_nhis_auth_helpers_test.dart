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
      tilkoNhisSimpleAuthIndicatesError({'ErrorCode': 0}),
      isFalse,
    );
    expect(
      tilkoNhisSimpleAuthIndicatesError({'ErrorCode': 12001}),
      isTrue,
    );
  });
}
