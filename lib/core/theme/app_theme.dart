import 'package:flutter/material.dart';

/// ???„ì—­ ?Œë§ˆ. ?‰Â·í??´í¬ë¥??œê³³?ì„œ ì¡°ì •?©ë‹ˆ??
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
      ),
    );
  }
}
