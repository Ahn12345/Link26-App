/// 여러 폴더에 복제본이 있을 때, **실제로 빌드에 쓰인** 트리를 구분합니다.
///
/// 실행 예:
/// `flutter run --dart-define=LINK26_TAG=dev`
/// `flutter run --dart-define=LINK26_TAG=github`
///
/// 디버그 빌드에서는 `app.dart` 상단 빨간 띠에 이 값(또는 미설정 안내)이 표시됩니다.
const String kLink26BuildTag = String.fromEnvironment(
  'LINK26_TAG',
  defaultValue: '',
);
