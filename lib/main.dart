import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/constants/api_keys.dart';
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/design/link26_design_catalog.dart';
import 'package:link26_app/core/services/dose_reminder_notifications.dart';
import 'package:link26_app/core/services/link26_bff_advice.dart';
import 'package:link26_app/core/services/link26_bff_reachability.dart';
import 'package:link26_app/core/services/link26_lan_bff_discovery.dart';
import 'package:link26_app/core/services/link26_remote_bff_bootstrap.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';

import 'app.dart';

/// Android 디버그 빌드는 APK에 에셋이 거의 없고 DevFS로 푸시됩니다.
/// [main] 이 [rootBundle] 접근을 너무 이르면 `AssetManifest.bin` 없음 예외가 납니다.
Future<void> _waitForDebugAndroidAssetBundle() async {
  if (!kDebugMode || defaultTargetPlatform != TargetPlatform.android) return;
  const step = Duration(milliseconds: 40);
  const maxAttempts = 120;
  for (var i = 0; i < maxAttempts; i++) {
    try {
      try {
        await rootBundle.loadString('AssetManifest.json');
        return;
      } catch (_) {
        await rootBundle.load('AssetManifest.bin');
        return;
      }
    } catch (_) {
      await Future<void>.delayed(step);
    }
  }
}

/// [dotenv.load] 는 파일 없음·빈 파일 등에서 예외를 던질 수 있고, 그러면 [dotenv] 가
/// 미초기화 상태로 남아 이후 `dotenv.env` 접근마다 [NotInitializedError] 가 납니다.
/// asset 문자열을 읽은 뒤 [dotenv.testLoad] 로 항상 초기화까지 마칩니다.
Future<void> _loadDotenvFromAssets() async {
  try {
    var raw = await rootBundle.loadString('assets/env/dotenv', cache: false);
    if (raw.isNotEmpty && raw.codeUnitAt(0) == 0xFEFF) {
      raw = raw.substring(1);
    }
    dotenv.testLoad(fileInput: raw);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        'Link26: dotenv 로드 실패 — `assets/env/dotenv` 및 루트 `.env` 확인, '
        '빌드 전 `tool/sync_dotenv_asset.ps1` 실행 후 flutter clean / 재빌드.',
      );
      debugPrint('Link26: detail: $e');
      debugPrint('$st');
    }
    dotenv.testLoad(fileInput: '');
  }
}

Future<void> _maybeDiscoverLanBff() async {
  if (!NhisRuntimeConfig.lanAutoDiscoverEnabled) return;
  if (Link26BffReachability.recentlyAllUnreachable) return;
  final found = await Link26LanBffDiscovery.discoverOnce(
    listenFor: const Duration(milliseconds: 1200),
  );
  NhisRuntimeConfig.setLanDiscoveredBases(found);
  await NhisRuntimeConfig.reorderLanDiscoveredForCurrentDevice();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _waitForDebugAndroidAssetBundle();
  await _loadDotenvFromAssets();
  await _maybeDiscoverLanBff();
  await NhisRuntimeConfig.refreshBffReachability();
  await Link26RemoteBffBootstrap.init();
  Link26RemoteBffBootstrap.scheduleBackgroundRefresh();
  // 실제 기기 릴리스: 캐시 없이 LINK26 만 쓰는 경우 첫 프레임 전에 주소를 채우기 위해
  // 한 번 동기로 받습니다(최대 ~10s). NHIS_PRODUCTION_BASE_URL 이 이미 있으면 생략.
  if (kReleaseMode &&
      ApiConfig.nhisProductionBaseUrl.trim().isEmpty &&
      Link26RemoteBffBootstrap.manifestUrl.trim().isNotEmpty &&
      NhisRuntimeConfig.baseUrl.isEmpty) {
    await Link26RemoteBffBootstrap.refreshFromNetwork(
      timeout: const Duration(seconds: 10),
    );
    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      developer.log(
        '릴리스: 원격 매니페스트 후에도 BFF base 비움 — JSON·네트워크·HTTPS(nhisBffBases) 확인',
        name: 'link26.nhis',
      );
    }
  }
  await Link26BffAdvice.evaluateAfterDotenv();
  if (kDebugMode) {
    final m = Link26RemoteBffBootstrap.manifestUrl.trim();
    debugPrint(
      'Link26: kReleaseMode=$kReleaseMode NHIS_USE_MOCK=${NhisRuntimeConfig.useMock} '
      'baseUrl="${NhisRuntimeConfig.baseUrl}" '
      'remoteManifest=${m.isEmpty ? "(비움)" : m}',
    );
  }
  await Link26DesignCatalog.load();
  await DoseReminderNotifications.init();
  await DoseReminderNotifications.rescheduleFromPrefs();
  if (kDebugMode) {
    final n = GeminiRuntimeConfig.apiKey.length;
    debugPrint(
      'Link26: Gemini keyLength=$n model=${GeminiRuntimeConfig.modelId} '
      '(0이면 앱이 키를 못 읽은 것. 키는 .env 또는 --dart-define=GEMINI_API_KEY=)',
    );
    // CODEF_CONNECTED_ID — CODEF 비활성화 시 로그 생략
    // final cid =
    //     (dotenv.env['CODEF_CONNECTED_ID'] ?? dotenv.env['NHIS_CODEF_CONNECTED_ID'] ?? '')
    //         .trim();
    // debugPrint(
    //   'Link26: CODEF_CONNECTED_ID length=${cid.length} '
    //   '(0이면 홈 복약 동기화 시 connectedId 안내가 날 수 있음. 설정 화면 또는 BFF .env 참고)',
    // );
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
