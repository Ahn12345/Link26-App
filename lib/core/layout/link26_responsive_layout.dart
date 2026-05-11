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

  /// 디자인 기준(폰) 폭. 더 넓은 기기에서는 [innerWidth] 가 단계적으로 커집니다.
  static double _designContentCap(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return Link26ResponsiveTokens.contentMaxWidth;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 720;
    }
    return 960;
  }

  /// 가운데 정렬 컬럼의 목표 너비(패딩 제외). 좁은 화면은 거의 전체 폭, 태블릿·데스크톱은 상한까지 확장.
  static double innerWidth(double width) {
    final side = _pagePaddingH(width);
    final available =
        (width - 2 * side).clamp(0.0, double.infinity);
    final cap = _designContentCap(width);
    return available <= cap ? available : cap;
  }

  /// [innerWidth] 만큼의 컬럼을 가운데 두기 위한 좌우 여백.
  static double horizontalPadding(double width) {
    final cw = innerWidth(width);
    return ((width - cw) / 2).clamp(0.0, double.infinity);
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
    return (innerWidth * f).clamp(120.0, innerWidth);
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
                maxWidth: Link26Layout.innerWidth(w),
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
                  maxWidth: Link26Layout.innerWidth(w),
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
