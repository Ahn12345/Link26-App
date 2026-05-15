import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_pass_launch.dart';

void main() {
  test('extractLaunchUrisFromTilko finds tauthlink and intent scheme', () {
    final uris = TilkoPassLaunch.extractLaunchUrisFromTilko({
      'ResultData': {
        'AppScheme': 'tauthlink://easypay?cx=abc',
      },
      'TargetMessage':
          'intent://request#Intent;scheme=tauthlink;package=com.sktelecom.tauth;end',
    });
    expect(uris, isNotEmpty);
    expect(
      uris.any((u) => u.toLowerCase().startsWith('tauthlink://')),
      isTrue,
    );
  });
}
