import 'package:flutter/material.dart';

import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';

/// Global theme configuration.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: Link26UnifiedPage.ctaBlue,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Link26UnifiedPage.background,
      // 하단 탭·본문 아이콘이 시스템 글꼴로 대체되며 깨지는 기기 완화(색·크기 고정).
      iconTheme: const IconThemeData(
        color: Link26Surface.textSecondary,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: scheme.onSurface,
        size: 24,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: Link26Surface.chipTint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Link26UnifiedPage.background,
        foregroundColor: Link26Surface.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Link26Surface.textPrimary,
        ),
        iconTheme: const IconThemeData(color: Link26Surface.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: Link26UnifiedPage.filledCtaButton(),
      ),
    );
  }
}