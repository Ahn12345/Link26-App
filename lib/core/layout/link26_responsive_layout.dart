import 'package:flutter/material.dart';

import 'package:link26_app/core/layout/link26_responsive_tokens.g.dart';

/// `link26_design_tokens.xml` 의 `<responsive/>` 값을 사용하는 레이아웃 헬퍼.
abstract final class Link26Layout {
  static double _pagePaddingH(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return Link26ResponsiveTokens.paddingCompact;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return Link26ResponsiveTokens.paddingMedium;
    }
    return Link26ResponsiveTokens.paddingExpanded;
  }

  /// 좁은 화면: 최소 측면 패딩. 넓은 화면: [contentMaxWidth] 가운데 정렬용 동일 여백.
  static double horizontalPadding(double width) {
    final minSide = _pagePaddingH(width);
    final maxContent = Link26ResponsiveTokens.contentMaxWidth;
    if (width <= maxContent + 2 * minSide) return minSide;
    return (width - maxContent) / 2;
  }

  /// 스크롤/폼 본문 실제 사용 가능 너비.
  static double innerWidth(double width) {
    final side = horizontalPadding(width);
    return (width - 2 * side).clamp(0, double.infinity);
  }

  static EdgeInsets pageInsets(double width) {
    final h = horizontalPadding(width);
    return EdgeInsets.fromLTRB(
      h,
      Link26ResponsiveTokens.pageTop,
      h,
      Link26ResponsiveTokens.pageBottom,
    );
  }

  static double heroImageHeight(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return Link26ResponsiveTokens.heroCompact;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return Link26ResponsiveTokens.heroMedium;
    }
    return Link26ResponsiveTokens.heroExpanded;
  }

  static double chatBubbleMaxWidth(double innerWidth) {
    final f = Link26ResponsiveTokens.chatBubbleMaxFraction;
    return (innerWidth * f).clamp(120, Link26ResponsiveTokens.contentMaxWidth);
  }

  static double chatListHorizontal(double width) {
    final side = horizontalPadding(width);
    return side < Link26ResponsiveTokens.chatSideMin
        ? Link26ResponsiveTokens.chatSideMin
        : side;
  }
}

/// 폼·리스트용: 가로 패딩 + (넓은 화면) 최대 너비 제한.
class Link26ResponsiveScroll extends StatelessWidget {
  const Link26ResponsiveScroll({
    super.key,
    required this.child,
    this.bottomInset = 0,
  });

  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pad = Link26Layout.pageInsets(w).copyWith(
          bottom: Link26Layout.pageInsets(w).bottom + bottomInset,
        );
        return SingleChildScrollView(
          padding: pad,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Link26ResponsiveTokens.contentMaxWidth,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// ListView 전용: 동일 패딩·maxWidth 를 스크롤 축에 적용.
class Link26ResponsiveList extends StatelessWidget {
  const Link26ResponsiveList({
    super.key,
    required this.children,
    this.bottomInset = 0,
  });

  final List<Widget> children;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final base = Link26Layout.pageInsets(w);
        final pad = base.copyWith(bottom: base.bottom + bottomInset);
        return ListView(
          padding: pad,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Link26ResponsiveTokens.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
