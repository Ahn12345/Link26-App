import 'package:flutter/material.dart';

import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';

/// 홈·AI 채팅 등에서 동일한 카드 룩(테두리·그림자).
BoxDecoration link26ElevatedCardDecoration({Color? color}) {
  return BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Link26Surface.outline),
    boxShadow: [
      BoxShadow(
        color: Link26Surface.cardShadow,
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Link26Surface.accent.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// 로그인·회원가입·약 검색 등 — 홈 '오늘의 알림' 카드와 맞춘 흰 프레임(20r · 은은한 그림자).
BoxDecoration link26FramedPageCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(Link26UnifiedPage.frameRadius),
    border: Border.all(color: Link26Surface.outline),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: Link26Surface.cardShadow,
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Link26Surface.accent.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class Link26FramedPageCard extends StatelessWidget {
  const Link26FramedPageCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.all(Link26UnifiedPage.framePadding),
      decoration: link26FramedPageCardDecoration(),
      child: child,
    );
  }
}

/// 홈 대시보드와 동일한 그림자·테두리 카드.
class Link26ElevatedCard extends StatelessWidget {
  const Link26ElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: link26ElevatedCardDecoration(),
      child: child,
    );
  }
}

/// 홈 섹션 타이틀 + 우측 액션(선택).
class Link26SectionHeader extends StatelessWidget {
  const Link26SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.icon,
    this.onAction,
  });

  final String title;
  final String? action;
  final IconData? icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = Link26ResponsiveUi.sectionHeader(w);
    final actionSize = Link26ResponsiveUi.sectionAction(w);
    final iconSz = Link26ResponsiveUi.sectionHeaderIcon(w);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: Link26Surface.textPrimary,
            ),
          ),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(icon, size: iconSz, color: Link26Surface.accent),
            label: Text(
              action!,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Link26Surface.accent,
                fontSize: actionSize,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}
