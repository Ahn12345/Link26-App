import 'package:flutter/material.dart';

// GENERATED FILE - do not edit by hand.
// Source: assets/design/link26_design_tokens.xml
// Regenerate: dart run tool/generate_link26_surface.dart

abstract final class Link26Surface {
  static const accent = Color(0xFF0046AD);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const outline = Color(0xFFE8EEF5);
  static const cardShadow = Color(0x14000000);
  static const scaffoldBg = Color(0xFFEEF4FA);
  static const chipTint = Color(0xFFEAF3FF);
  static const badgeTint = Color(0xFFEAF2FF);

  static const List<Color> backdropGradient = [
    Color(0xFFE4EEF8),
    Color(0xFFEEF4FA),
    Color(0xFFF5F9FD),
  ];

  static const double radiusInput = 12.0;
  static const double radiusButton = 12.0;

  static ButtonStyle filledAccentButton({Size? minimumSize}) =>
      FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: minimumSize ?? const Size(0, 56.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
      );

  static OutlineInputBorder outlineInputBorder([Color? border]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: border ?? outline),
      );

  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
  }) =>
      InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: outlineInputBorder(),
        enabledBorder: outlineInputBorder(),
        focusedBorder: outlineInputBorder(accent),
      );
}
