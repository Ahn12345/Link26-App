import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/core/services/codef_flow_connected_id_parse.dart';

void main() {
  group('parseConnectedIdFromBffFlowResponse', () {
    test('루트 connectedId (공백 트림)', () {
      expect(
        parseConnectedIdFromBffFlowResponse({'connectedId': '  cid-root  '}),
        'cid-root',
      );
    });

    test('루트 connected_id', () {
      expect(
        parseConnectedIdFromBffFlowResponse({'connected_id': 'cid-snake'}),
        'cid-snake',
      );
    });

    test('meta.connectedId (BFF echo)', () {
      expect(
        parseConnectedIdFromBffFlowResponse({
          'ok': true,
          'meta': {
            'source': 'tilko_codef_nhis',
            'connectedId': 'from-meta',
          },
        }),
        'from-meta',
      );
    });

    test('codef.data.connectedId (CODEF 흔한 형태)', () {
      expect(
        parseConnectedIdFromBffFlowResponse({
          'ok': true,
          'codef': {
            'result': {'code': 'CF-00000'},
            'data': {'connectedId': 'deep-data'},
          },
        }),
        'deep-data',
      );
    });

    test('codef.data.res.connectedId', () {
      expect(
        parseConnectedIdFromBffFlowResponse({
          'codef': {
            'data': {
              'res': {'connectedId': 'nested-res'},
            },
          },
        }),
        'nested-res',
      );
    });

    test('없으면 null', () {
      expect(parseConnectedIdFromBffFlowResponse({'ok': true, 'items': []}), isNull);
    });
  });

  group('parseConnectedIdFromCodefRootMap (BFF와 동일)', () {
    test('루트 키', () {
      expect(
        parseConnectedIdFromCodefRootMap({'connectedId': 'x'}),
        'x',
      );
    });

    test('data 안', () {
      expect(
        parseConnectedIdFromCodefRootMap({
          'data': {'connected_id': 'y'},
        }),
        'y',
      );
    });
  });
}
