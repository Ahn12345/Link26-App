// ignore_for_file: avoid_print

import 'dart:io';

import 'package:xml/xml.dart';

/// `assets/design/link26_design_tokens.xml` → `lib/core/theme/link26_surface_style.dart`
void main() {
  final root = Directory.current;
  final xmlPath = '${root.path}/assets/design/link26_design_tokens.xml';
  final outPath = '${root.path}/lib/core/theme/link26_surface_style.dart';
  final doc = XmlDocument.parse(File(xmlPath).readAsStringSync());

  final design = doc.rootElement;
  if (design.localName != 'link26-design') {
    throw StateError('Root must be link26-design');
  }

  final colors = <String, String>{};
  final colorsEl = design.getElement('colors');
  if (colorsEl != null) {
    for (final el in colorsEl.findElements('color')) {
      final name = el.getAttribute('name');
      final hex = el.innerText.trim();
      if (name != null && hex.isNotEmpty) {
        colors[name] = hex;
      }
    }
  }

  final dimens = <String, double>{};
  final dimensEl = design.getElement('dimens');
  if (dimensEl != null) {
    for (final el in dimensEl.findElements('dimen')) {
      final name = el.getAttribute('name');
      final v = double.tryParse(el.innerText.trim());
      if (name != null && v != null) {
        dimens[name] = v;
      }
    }
  }

  final backdropStops = <String>[];
  final gradEl = design.getElement('gradients');
  XmlElement? backdrop;
  if (gradEl != null) {
    for (final g in gradEl.findElements('gradient')) {
      if (g.getAttribute('name') == 'backdrop') {
        backdrop = g;
        break;
      }
    }
  }
  if (backdrop != null) {
    for (final s in backdrop.findElements('stop')) {
      final h = s.innerText.trim();
      if (h.isNotEmpty) backdropStops.add(h);
    }
  }

  String dartColorConst(String name) {
    final hex = colors[name];
    if (hex == null) throw StateError('Missing color: $name');
    return 'Color(${_hexToDart(hex)})';
  }

  final radiusInput = dimens['radius_input'] ?? 12;
  final radiusButton = dimens['radius_button'] ?? 12;

  final gradientLines = backdropStops.map((h) => '    Color(${_hexToDart(h)}),').join('\n');

  final out = '''
import 'package:flutter/material.dart';

// GENERATED FILE - do not edit by hand.
// Source: assets/design/link26_design_tokens.xml
// Regenerate: dart run tool/generate_link26_surface.dart

abstract final class Link26Surface {
  static const accent = ${dartColorConst('accent')};
  static const textPrimary = ${dartColorConst('text_primary')};
  static const textSecondary = ${dartColorConst('text_secondary')};
  static const textMuted = ${dartColorConst('text_muted')};
  static const outline = ${dartColorConst('outline')};
  static const cardShadow = ${dartColorConst('card_shadow')};
  static const scaffoldBg = ${dartColorConst('scaffold_bg')};
  static const chipTint = ${dartColorConst('chip_tint')};
  static const badgeTint = ${dartColorConst('badge_tint')};

  static const List<Color> backdropGradient = [
$gradientLines
  ];

  static const double radiusInput = $radiusInput;
  static const double radiusButton = $radiusButton;

  static ButtonStyle filledAccentButton({Size? minimumSize}) =>
      FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: minimumSize ?? const Size(0, 48),
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
''';

  File(outPath).writeAsStringSync(out);
  print('Wrote $outPath');
}

String _hexToDart(String hex) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) return '0xFF$h';
  if (h.length == 8) return '0x$h';
  throw FormatException('Invalid hex: $hex');
}
