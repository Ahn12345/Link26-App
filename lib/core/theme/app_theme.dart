import 'package:flutter/material.dart';

/// Global theme configuration.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0047AB),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      /// 홈·탭 공통 배경 톤 (시안 연블루).
      scaffoldBackgroundColor: const Color(0xFFEEF4FA),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.65),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
      ),
    );
  }
}