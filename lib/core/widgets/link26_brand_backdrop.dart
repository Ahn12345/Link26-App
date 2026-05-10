import 'package:flutter/material.dart';

import 'package:link26_app/core/theme/link26_surface_style.dart';

/// 환영·로그인·회원가입·약 검색 등 브랜드 화면 공통 배경 (`link26_design_tokens` backdrop 그라데이션).
class Link26BrandBackdrop extends StatelessWidget {
  const Link26BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
