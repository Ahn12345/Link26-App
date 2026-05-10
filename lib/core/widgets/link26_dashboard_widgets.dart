import 'package:flutter/material.dart';

import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';

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
      decoration: BoxDecoration(
        color: Colors.white,
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
      ),
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
