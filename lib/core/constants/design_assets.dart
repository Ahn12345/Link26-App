/// 탭·배경용 `assets/images/` 경로.
///
/// 홈 탭은 `Home.png` 같은 **전체 UI 목업**을 배경으로 깔면 카드 UI와 겹쳐 보이므로,
/// 기본은 배경 이미지 없음(그라데이션만). **배경 전용** PNG를 쓸 때만 [homeFullBackground] 에 경로를 넣으면 됨.
library;

enum DesignFit {
  screenCover,
  widthScroll,
  containLetterbox,
}

abstract final class DesignAssets {
  /// 비우면 [FullScreenAssetBackground] 가 이미지 레이어를 생략하고 그라데이션만 씀.
  static const String homeFullBackground = '';

  static const String? homeBackground = null;
}
