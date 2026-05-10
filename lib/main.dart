import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/debug_build_label.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode && kLink26BuildTag.isNotEmpty) {
    debugPrint(
      '=== LINK26_TAG="$kLink26BuildTag" (화면 우측 상단 주황 뱃지) ===',
    );
  }
  // runApp 을 막지 않음 — 첫 프레임·스플래시가 바로 뜨고, .env 는 백그라운드 로드.
  unawaited(
    dotenv.load(fileName: '.env').catchError((Object? _) {}),
  );
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
