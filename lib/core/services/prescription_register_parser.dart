import 'dart:convert';

/// Gemini·붙여넣기 응답에서 약품명 목록을 추출합니다.
abstract final class PrescriptionRegisterParser {
  static final _lineDrugHint = RegExp(
    r'(정|캡슐|연고|시럽|현탁|주|액|필름|패치|mg|㎎|g\b|ml|밀리그램)',
    caseSensitive: false,
  );

  static List<String> parseFromModelText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    final jsonSlice = _extractJsonArraySlice(trimmed);
    if (jsonSlice != null) {
      try {
        final decoded = jsonDecode(jsonSlice);
        if (decoded is List) {
          return _dedupeStrings(
            decoded.map((e) => '$e'.trim()).where((s) => s.length >= 2),
          );
        }
      } catch (_) {}
    }

    return parseFromPastedText(trimmed);
  }

  static String? _extractJsonArraySlice(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start < 0 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  /// OCR·처방전 텍스트 붙여넣기 — 줄 단위로 약 후보를 고릅니다.
  static List<String> parseFromPastedText(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    final out = <String>[];
    for (final line in lines) {
      var s = line.trim();
      if (s.length < 2) continue;
      s = s.replaceFirst(RegExp(r'^[\d\.\)\-\*•·]+\s*'), '');
      s = s.replaceFirst(RegExp(r'^(약품명|처방|품목)\s*[:：]\s*'), '');
      if (s.length < 2) continue;
      if (!_lineDrugHint.hasMatch(s) && s.length < 4) continue;
      if (RegExp(r'^(병원|의료|진료|환자|주민|성명|생년|일자|날짜)').hasMatch(s)) {
        continue;
      }
      out.add(s);
    }
    return _dedupeStrings(out);
  }

  static List<String> _dedupeStrings(Iterable<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in items) {
      final n = s.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (n.length < 2) continue;
      final key = n.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(n);
    }
    return out;
  }
}
