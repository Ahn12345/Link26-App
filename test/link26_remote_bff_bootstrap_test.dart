import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/core/services/link26_remote_bff_bootstrap.dart';

void main() {
  group('Link26RemoteBffBootstrap.parseManifestBody', () {
    test('nhisBffBases array', () {
      const body =
          '{"nhisBffBases":["https://api.example.com/","https://backup.example.com"]}';
      final list = Link26RemoteBffBootstrap.parseManifestBody(body);
      expect(list, [
        'https://api.example.com',
        'https://backup.example.com',
      ]);
    });

    test('nhisBffBase comma-separated', () {
      const body =
          '{"nhisBffBase":"https://a.example.com, https://b.example.com"}';
      final list = Link26RemoteBffBootstrap.parseManifestBody(body);
      expect(list, ['https://a.example.com', 'https://b.example.com']);
    });

    test('nhis_production_base_url alias', () {
      const body = '{"nhis_production_base_url":"https://prod.example.com/"}';
      final list = Link26RemoteBffBootstrap.parseManifestBody(body);
      expect(list, ['https://prod.example.com']);
    });

    test('invalid JSON returns empty', () {
      expect(Link26RemoteBffBootstrap.parseManifestBody('not json'), isEmpty);
    });

    test('leading UTF-8 BOM', () {
      const body = '\uFEFF{"nhisBffBases":["https://bom.example.com"]}';
      final list = Link26RemoteBffBootstrap.parseManifestBody(body);
      expect(list, ['https://bom.example.com']);
    });
  });
}
