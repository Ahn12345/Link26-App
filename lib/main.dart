import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/design/link26_design_catalog.dart';

import 'app.dart';

/// [dotenv.load] 는 파일 없음·빈 파일 등에서 예외를 던질 수 있고, 그러면 [dotenv] 가
/// 미초기화 상태로 남아 이후 `dotenv.env` 접근마다 [NotInitializedError] 가 납니다.
/// asset 문자열을 읽은 뒤 [dotenv.testLoad] 로 항상 초기화까지 마칩니다.
Future<void> _loadDotenvFromAssets() async {
  try {
    var raw = await rootBundle.loadString('.env', cache: false);
    if (raw.isNotEmpty && raw.codeUnitAt(0) == 0xFEFF) {
      raw = raw.substring(1);
    }
    dotenv.testLoad(fileInput: raw);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        'Link26: .env 로드 실패 — pubspec assets에 `.env`가 있는지, '
        '프로젝트 루트에 파일이 있는지 확인 후 flutter clean / 재빌드 하세요.',
      );
      debugPrint('Link26: detail: $e');
      debugPrint('$st');
    }
    dotenv.testLoad(fileInput: '');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadDotenvFromAssets();
  await Link26DesignCatalog.load();
  if (kDebugMode) {
    final n = GeminiRuntimeConfig.apiKey.length;
    debugPrint(
      'Link26: Gemini keyLength=$n model=${GeminiRuntimeConfig.modelId} '
      '(0이면 앱이 키를 못 읽은 것. 키는 .env 또는 --dart-define=GEMINI_API_KEY=)',
    );
    final cid =
        (dotenv.env['CODEF_CONNECTED_ID'] ?? dotenv.env['NHIS_CODEF_CONNECTED_ID'] ?? '')
            .trim();
    debugPrint(
      'Link26: CODEF_CONNECTED_ID length=${cid.length} '
      '(0이면 홈 복약 동기화 시 connectedId 안내가 날 수 있음. 설정 화면 또는 BFF .env 참고)',
    );
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const Link26App());
}
