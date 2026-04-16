#개발 배경 및 팀 구성

동국대 무빙 동아리 팀으로 구성

안병찬(PM, 개발)
하윤서(UI/UX)
이기훈(UI/UX)
유송현(경쟁사 분석과 BM 모델 제작)
이세현(바이오 아이디어 제공)

바이오 공모전을 위해 제작

# Bio Link App

Flutter **모바일 앱** (Android / iOS).

앱 화면에서 쓰는 이미지·아이콘·애니메이션은 **`assets/images/`**, **`assets/icons/`**, **`assets/animations/`** 에 두면 iOS·Android **같은 경로**로 빌드에 포함됩니다 (`pubspec.yaml`의 `assets:` 참고). 홈 화면 **앱 아이콘**만 플랫폼별 폴더가 따로 있으며, 원본 한 장으로 맞추려면 `flutter_launcher_icons` 같은 도구를 쓰면 됩니다.

## 환경 변수

비밀 값은 **`.env`** 에만 두고, 저장소에는 **올리지 않습니다** (`.gitignore`).

1. 루트에서 `.env.example` 을 복사해 `.env` 로 저장합니다.  
2. 필요한 키와 값을 채웁니다.  
3. `flutter_dotenv` 등 패키지를 쓰면 `pubspec.yaml` 에 의존성을 추가한 뒤, 앱 시작 시 로드하도록 연결하면 됩니다.

## 실행

```bash
flutter pub get
flutter run
```

자세한 내용은 [Flutter 문서](https://docs.flutter.dev/)를 참고하세요.
