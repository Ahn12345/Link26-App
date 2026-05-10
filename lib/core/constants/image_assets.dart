// `assets/images/` 실제 파일만. 다른 경로 문자열을 코드에 흩뿌리지 않습니다.
// 에셋 목록·용도는 `assets/images/link26_image_assets.xml` 과 함께 유지합니다.

abstract final class ImageAssets {
  /// PNG 목록·기능 매핑(XML). 런타임 로드용이 아니라 문서·동기화 참조.
  static const manifestXml = 'assets/images/link26_image_assets.xml';

  static const applogo = 'assets/images/applogo.png';
  static const logo = 'assets/images/logo.png';
  static const login = 'assets/images/login.png';
  static const signup = 'assets/images/signup.png';
  static const home = 'assets/images/Home.png';
  static const aichat = 'assets/images/aichat.png';
  static const setting = 'assets/images/setting.png';
  static const pillsearch = 'assets/images/pillsearch.png';
  static const emergencycall = 'assets/images/emergencycall.png';
  static const familyadd = 'assets/images/familyadd.png';
  static const simplelogin1 = 'assets/images/simplelogin1.png';
  static const simplelogin2 = 'assets/images/simplelogin2.png';

  /// 홈 탭: 전체 목업 PNG 를 깔지 않음(대시보드와 중복 방지).
  static const String homeTabBackground = '';
}
