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

  _writeResponsiveTokens(root, design);
  _writeResponsiveImageTokens(root);
  _writeResponsiveUiTokens(root);
}

void _writeResponsiveTokens(Directory root, XmlElement design) {
  final resp = design.getElement('responsive');
  double d(String key, double fallback) {
    final raw = resp?.getAttribute(key);
    if (raw == null || raw.isEmpty) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  final bc = d('breakpointCompact', 600);
  final bm = d('breakpointMedium', 900);
  final cmw = d('contentMaxWidth', 520);
  final pc = d('paddingCompact', 16);
  final pm = d('paddingMedium', 22);
  final pe = d('paddingExpanded', 32);
  final pt = d('pageTop', 16);
  final pbot = d('pageBottom', 24);
  final hc = d('heroCompact', 140);
  final hm = d('heroMedium', 170);
  final he = d('heroExpanded', 200);
  final cbf = d('chatBubbleMaxFraction', 0.92);
  final csm = d('chatSideMin', 12);

  final outPath = '${root.path}/lib/core/layout/link26_responsive_tokens.g.dart';
  File(outPath).parent.createSync(recursive: true);
  File(outPath).writeAsStringSync('''
// GENERATED FILE - do not edit by hand.
// Source: assets/design/link26_design_tokens.xml (<responsive/>)
// Regenerate: dart run tool/generate_link26_surface.dart

abstract final class Link26ResponsiveTokens {
  static const double breakpointCompact = $bc;
  static const double breakpointMedium = $bm;
  static const double contentMaxWidth = $cmw;
  static const double paddingCompact = $pc;
  static const double paddingMedium = $pm;
  static const double paddingExpanded = $pe;
  static const double pageTop = $pt;
  static const double pageBottom = $pbot;
  static const double heroCompact = $hc;
  static const double heroMedium = $hm;
  static const double heroExpanded = $he;
  static const double chatBubbleMaxFraction = $cbf;
  static const double chatSideMin = $csm;
}
''');
  print('Wrote $outPath');
}

/// `assets/design/link26_responsive_images.xml` → `link26_responsive_image_tokens.g.dart`
void _writeResponsiveImageTokens(Directory root) {
  final xmlPath = '${root.path}/assets/design/link26_responsive_images.xml';
  final file = File(xmlPath);
  if (!file.existsSync()) {
    print('Skip responsive image tokens (missing $xmlPath)');
    return;
  }
  final doc = XmlDocument.parse(file.readAsStringSync());
  final rootEl = doc.rootElement;
  if (rootEl.localName != 'link26-responsive-images') {
    throw StateError('Root must be link26-responsive-images');
  }

  final screens = <_ScreenImageSpec>[];
  for (final el in rootEl.findElements('screen')) {
    final id = el.getAttribute('id');
    if (id == null || id.isEmpty) continue;
    final hEl = el.getElement('height');
    if (hEl == null) {
      throw StateError('screen "$id" missing <height/>');
    }
    final c = double.parse(hEl.getAttribute('compact') ?? '');
    final m = double.parse(hEl.getAttribute('medium') ?? '');
    final e = double.parse(hEl.getAttribute('expanded') ?? '');
    final wfEl = el.getElement('widthFraction');
    final cap = double.tryParse(wfEl?.getAttribute('cap') ?? '') ?? 1.0;
    screens.add(_ScreenImageSpec(id: id, compact: c, medium: m, expanded: e, widthCap: cap));
  }

  final buf = StringBuffer()
    ..writeln('// GENERATED FILE - do not edit by hand.')
    ..writeln('// Source: assets/design/link26_responsive_images.xml')
    ..writeln('// Regenerate: dart run tool/generate_link26_surface.dart')
    ..writeln()
    ..writeln("import 'link26_responsive_layout.dart';")
    ..writeln("import 'link26_responsive_tokens.g.dart';")
    ..writeln()
    ..writeln('abstract final class Link26ResponsiveImageHeights {');

  final idPattern = RegExp(r'^[a-z][a-zA-Z0-9]*$');

  for (final s in screens) {
    if (!idPattern.hasMatch(s.id)) {
      throw StateError(
        'screen id "${s.id}" must be a lowerCamelCase Dart identifier (e.g. pillSearch)',
      );
    }
    final base = s.id;
    buf
      ..writeln('  static double $base(double width) {')
      ..writeln('    if (width < Link26ResponsiveTokens.breakpointCompact) {')
      ..writeln('      return ${s.compact};')
      ..writeln('    }')
      ..writeln('    if (width < Link26ResponsiveTokens.breakpointMedium) {')
      ..writeln('      return ${s.medium};')
      ..writeln('    }')
      ..writeln('    return ${s.expanded};')
      ..writeln('  }')
      ..writeln()
      ..writeln(
        '  static double ${base}DisplayWidth(double width) => '
        '(Link26Layout.innerWidth(width) * ${s.widthCap}).clamp(0.0, double.infinity);',
      )
      ..writeln();
  }

  buf.writeln('}');

  final outPath = '${root.path}/lib/core/layout/link26_responsive_image_tokens.g.dart';
  File(outPath).parent.createSync(recursive: true);
  File(outPath).writeAsStringSync(buf.toString());
  print('Wrote $outPath');
}

class _ScreenImageSpec {
  const _ScreenImageSpec({
    required this.id,
    required this.compact,
    required this.medium,
    required this.expanded,
    required this.widthCap,
  });

  final String id;
  final double compact;
  final double medium;
  final double expanded;
  final double widthCap;
}

/// `assets/design/link26_responsive_ui.xml` → `link26_responsive_ui_tokens.g.dart`
void _writeResponsiveUiTokens(Directory root) {
  final xmlPath = '${root.path}/assets/design/link26_responsive_ui.xml';
  final file = File(xmlPath);
  if (!file.existsSync()) {
    print('Skip responsive UI tokens (missing $xmlPath)');
    return;
  }
  final doc = XmlDocument.parse(file.readAsStringSync());
  final rootEl = doc.rootElement;
  if (rootEl.localName != 'link26-responsive-ui') {
    throw StateError('Root must be link26-responsive-ui');
  }

  final idPattern = RegExp(r'^[a-z][a-zA-Z0-9]*$');
  final buf = StringBuffer()
    ..writeln('// GENERATED FILE - do not edit by hand.')
    ..writeln('// Source: assets/design/link26_responsive_ui.xml')
    ..writeln('// Regenerate: dart run tool/generate_link26_surface.dart')
    ..writeln()
    ..writeln("import 'link26_responsive_tokens.g.dart';")
    ..writeln()
    ..writeln('abstract final class Link26ResponsiveUi {');

  for (final el in rootEl.findElements('token')) {
    final id = el.getAttribute('id');
    if (id == null || id.isEmpty) continue;
    if (!idPattern.hasMatch(id)) {
      throw StateError('token id "$id" must be lowerCamelCase');
    }
    final c = double.parse(el.getAttribute('compact') ?? '');
    final m = double.parse(el.getAttribute('medium') ?? '');
    final e = double.parse(el.getAttribute('expanded') ?? '');
    buf
      ..writeln('  static double $id(double width) {')
      ..writeln('    if (width < Link26ResponsiveTokens.breakpointCompact) {')
      ..writeln('      return $c;')
      ..writeln('    }')
      ..writeln('    if (width < Link26ResponsiveTokens.breakpointMedium) {')
      ..writeln('      return $m;')
      ..writeln('    }')
      ..writeln('    return $e;')
      ..writeln('  }')
      ..writeln();
  }

  buf.writeln('}');

  final outPath = '${root.path}/lib/core/layout/link26_responsive_ui_tokens.g.dart';
  File(outPath).parent.createSync(recursive: true);
  File(outPath).writeAsStringSync(buf.toString());
  print('Wrote $outPath');
}

String _hexToDart(String hex) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) return '0xFF$h';
  if (h.length == 8) return '0x$h';
  throw FormatException('Invalid hex: $hex');
}
