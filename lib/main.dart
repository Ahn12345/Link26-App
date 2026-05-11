import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/constants/gemini_runtime_config.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        'Link26: .env 로드 실패 — 파일이 없거나 assets에 없을 수 있습니다. '
        'pubspec.yaml에 `.env`가 있고 프로젝트 루트에 파일이 있는지 확인 후 flutter clean / 재빌드 하세요. $e',
      );
      debugPrint('$st');
    }
  }
  if (kDebugMode) {
    final n = GeminiRuntimeConfig.apiKey.length;
    debugPrint(
      'Link26: Gemini keyLength=$n model=${GeminiRuntimeConfig.modelId} '
      '(0이면 앱이 키를 못 읽은 것. 키는 .env 또는 --dart-define=GEMINI_API_KEY=)',
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
