import 'package:flutter/foundation.dart';

/// 여러 폴더에 복제본이 있을 때, **실제로 빌드에 쓰인** 트리를 구분합니다.
///
/// 실행 예:
/// `flutter run --dart-define=LINK26_TAG=dev`
/// `flutter run --dart-define=LINK26_TAG=github`
///
/// 짧은 문자열만 사용하세요(모서리 배너 표시).
const String kLink26BuildTag = String.fromEnvironment(
  'LINK26_TAG',
  defaultValue: '',
);

bool get kLink26ShowBuildTagBanner =>
    kDebugMode && kLink26BuildTag.isNotEmpty;
