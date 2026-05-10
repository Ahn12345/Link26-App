/// 탭별 목업 경로(`assets/images/`) 및 표시 방식.
///
/// 파일명: `ui_home.png`, `ui_ai_chat.png`, `ui_more.png`
/// 전환: [DesignAssets.imageFit] 한 줄 변경 시 세 탭 모두 적용.
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
  static const home = 'assets/images/ui_home.png';
  static const aiChat = 'assets/images/ui_ai_chat.png';
  static const more = 'assets/images/ui_more.png';

  /// 배경까지 꽉 채우려면 [DesignFit.screenCover],
  /// 디자인 가로폭에 맞추고 세로 스크롤은 [DesignFit.widthScroll].
  static const DesignFit imageFit = DesignFit.screenCover;
}
