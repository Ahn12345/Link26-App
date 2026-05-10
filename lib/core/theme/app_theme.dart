import 'package:flutter/material.dart';

/// Global theme configuration.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6BFF),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F8FC),
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