import 'package:flutter/material.dart';

import 'package:link26_app/core/theme/link26_surface_style.dart';

/// 알파 통일 레이아웃 — 홈과 같은 계열의 페이지 배경·히어로 카드 프레임·CTA 색.
abstract final class Link26UnifiedPage {
  Link26UnifiedPage._();

  static const background = Color(0xFFF3F8FF);
  static const ctaBlue = Color(0xFF0046AD);
  static const frameRadius = 20.0;
  static const framePadding = 20.0;

  static ButtonStyle filledCtaButton({Size? minimumSize}) =>
      FilledButton.styleFrom(
        backgroundColor: ctaBlue,
        foregroundColor: Colors.white,
        minimumSize: minimumSize ?? const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Link26Surface.radiusButton),
        ),
      );
}
