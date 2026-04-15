# Bio Link App

Flutter **모바일 앱** (Android / iOS).

앱 화면에서 쓰는 이미지·아이콘·애니메이션은 **`assets/images/`**, **`assets/icons/`**, **`assets/animations/`** 에 두면 iOS·Android **같은 경로**로 빌드에 포함됩니다 (`pubspec.yaml`의 `assets:` 참고). 홈 화면 **앱 아이콘**만 플랫폼별 폴더가 따로 있으며, 원본 한 장으로 맞추려면 `flutter_launcher_icons` 같은 도구를 쓰면 됩니다.

## 실행

```bash
flutter pub get
flutter run
```

자세한 내용은 [Flutter 문서](https://docs.flutter.dev/)를 참고하세요.
