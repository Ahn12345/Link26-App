/// 탭·배경용 `assets/images/` 경로.
///
/// 단일 출처: `assets/images/link26_image_registry.xml` 과 동일한 PNG 파일명을 가리켜야 함.
library;

enum DesignFit {
  /// 화면 전체 덮음 (비율 유지, 잘림 허용).
  screenCover,

  /// 가로 = 기기 너비, 세로는 비율·스크롤.
  widthScroll,

  /// 이미지 전체 표시, 레터박스.
  containLetterbox,
}

abstract final class DesignAssets {
  /// 홈 탭 전체 배경 (`Home.png`).
  static const homeFullBackground = 'assets/images/Home.png';

  /// (선택) 보조 배경 — 별도 파일이 없으면 null 로 두고 그라데이션만 노출.
  static const String? homeBackground = null;

  /// 목업·참고용: 홈 / AI / 더보기 탭에 대응하는 현재 에셋.
  static const home = 'assets/images/Home.png';
  static const aiChat = 'assets/images/aichat.png';
  static const more = 'assets/images/setting.png';

  /// AI 채팅 시안 배경.
  static const aiChatFullBackground = 'assets/images/aichat.png';

  /// 배경까지 꽉 채우려면 [DesignFit.screenCover],
  /// 디자인 가로폭에 맞추고 세로 스크롤은 [DesignFit.widthScroll].
  static const DesignFit imageFit = DesignFit.screenCover;
}
