import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/integrations/tilko/tilko_env_resolver.dart';

void main() {
  test('production mode uses api.tilko.net and PROD key', () {
    final env = <String, String>{
      'TILKO_USE_PRODUCTION': 'true',
      'TILKO_API_KEY_DEMO': 'demo-key',
      'TILKO_API_KEY_PROD': 'prod-key',
    };
    TilkoEnvResolver.applyTo(env);
    expect(env['TILKO_API_HOST'], TilkoEnvResolver.prodHost);
    expect(env['TILKO_API_KEY'], 'prod-key');
  });

  test('demo mode uses dev.tilko.net and DEMO key', () {
    final env = <String, String>{
      'TILKO_USE_PRODUCTION': 'false',
      'TILKO_API_KEY_DEMO': 'demo-key',
      'TILKO_API_KEY_PROD': 'prod-key',
    };
    TilkoEnvResolver.applyTo(env);
    expect(env['TILKO_API_HOST'], TilkoEnvResolver.demoHost);
    expect(env['TILKO_API_KEY'], 'demo-key');
  });
}
