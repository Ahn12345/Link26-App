// `assets/images/` 실제 PNG. 다른 경로 문자열을 코드에 흩뿌리지 않습니다.
// 목록·용도: `assets/images/link26_image_assets.xml`
// PNG가 없으면: `dart run tool/gen_image_assets.dart`
// PNG·카탈로그 기준 XML 제작 갱신: `dart run tool/sync_image_specs_from_assets.dart`

abstract final class ImageAssets {
  /// PNG 목록·기능 매핑(XML). 런타임 로드용이 아니라 문서·동기화 참조.
  static const manifestXml = 'assets/images/link26_image_assets.xml';

  static const applogo = 'assets/images/applogo.png';
  /// 로그인·회원가입 히어로 — 파일명 그대로(`로고.png`).
  static const logoKo = 'assets/images/로고.png';
  static const logo = 'assets/images/logo.png';
  static const login = 'assets/images/login.png';
  static const signup = 'assets/images/signup.png';
  static const home = 'assets/images/home.png';
  static const aichat = 'assets/images/aichat.png';
  static const setting = 'assets/images/setting.png';
  static const pillsearch = 'assets/images/pillsearch.png';
  static const emergencycall = 'assets/images/emergencycall.png';
  static const familyadd = 'assets/images/familyadd.png';
  static const simplelogin1 = 'assets/images/simplelogin1.png';
  static const simplelogin2 = 'assets/images/simplelogin2.png';
}
