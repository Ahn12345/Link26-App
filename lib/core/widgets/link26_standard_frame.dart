import 'package:flutter/material.dart';

import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';

/// 인증·검색 등 공통: [Link26UnifiedPage.background] + 페이지 인셋 + [innerWidth] 중앙 정렬.
/// 디자인 토큰(`link26_design_tokens.xml`의 responsive padding)과 [Link26Layout]을 그대로 따릅니다.
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
    final pad = paddingOverride ?? Link26Layout.pageInsets(w);
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
