import 'package:flutter/material.dart';

import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';

/// 인증·검색·탭 내 페이지 공통: 배경 `#F3F8FF` + 표준 여백(좌우 16·상하 20) + [innerWidth] 중앙 정렬.
/// [paddingOverride] 없을 때는 [Link26UnifiedPage.standardFramePadding]을 씁니다.
class Link26StandardFrame extends StatelessWidget {
  const Link26StandardFrame({
    super.key,
    required this.child,
    this.paddingOverride,
  });

  final Widget child;
  final EdgeInsets? paddingOverride;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = paddingOverride ?? Link26UnifiedPage.standardFramePadding;
    return ColoredBox(
      color: Link26UnifiedPage.background,
      child: Padding(
        padding: pad,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Link26Layout.innerWidth(w)),
            child: child,
          ),
        ),
      ),
    );
  }
}
