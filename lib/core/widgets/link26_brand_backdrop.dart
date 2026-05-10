import 'package:flutter/material.dart';

import 'package:link26_app/core/theme/link26_surface_style.dart';

/// 환영·로그인·회원가입·약 검색 등 브랜드 화면 배경.
/// [solidBackground] 가 있으면 홈과 통일된 단색, 없으면 디자인 토큰 그라데이션.
class Link26BrandBackdrop extends StatelessWidget {
  const Link26BrandBackdrop({
    super.key,
    required this.child,
    this.solidBackground,
  });

  final Widget child;

  /// 홈·폼 통일용 연한 하늘색 등. null 이면 [Link26Surface.backdropGradient].
  final Color? solidBackground;

  @override
  Widget build(BuildContext context) {
    if (solidBackground != null) {
      return ColoredBox(color: solidBackground!, child: child);
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Link26Surface.backdropGradient,
        ),
      ),
      child: child,
    );
  }
}
