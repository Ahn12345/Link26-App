import 'dart:convert';

import 'package:flutter/services.dart';

/// `lib/data/DUR1`, `DUR2` CSV 에서 사용자 입력과 겹치는 행만 뽑아 프롬프트용으로 넣습니다.
/// (전체 CSV를 Gemini에 넣지 않음)
abstract final class DurAssetContext {
  static const _dur1Asset =
      'lib/data/DUR1/DUR품목 누적데이터(병용금기)(2025년).csv';
  static const _dur2Asset =
      'lib/data/DUR2/DUR품목 누적데이터(노인주의)(2025년).csv';

  static List<String>? _dur1Lines;
  static List<String>? _dur2Lines;

  static Future<void> _ensureLoaded() async {
    if (_dur1Lines != null && _dur2Lines != null) return;
    try {
      final raw1 = await rootBundle.loadString(_dur1Asset);
      _dur1Lines = const LineSplitter().convert(raw1);
    } catch (_) {
      _dur1Lines = const [];
    }
    try {
      final raw2 = await rootBundle.loadString(_dur2Asset);
      _dur2Lines = const LineSplitter().convert(raw2);
    } catch (_) {
      _dur2Lines = const [];
    }
  }

  /// DUR2(UTF-8) 우선 검색 후 DUR1. [maxLines] 줄까지 잘라서 반환.
  static Future<String> buildSnippetForQuery(
    String userText, {
    int maxLines = 14,
    int maxLineLength = 400,
  }) async {
    await _ensureLoaded();
    final t = userText.trim();
    if (t.length < 2) {
      return '(DUR 검색: 사용자 텍스트가 너무 짧음)';
    }
    final q = t.toLowerCase();
    final tokens = q
        .split(RegExp(r'[\s,.]+'))
        .where((e) => e.length >= 2)
        .take(12)
        .toList();

    bool matches(String line) {
      final low = line.toLowerCase();
      if (low.contains(q)) return true;
      return tokens.any(low.contains);
    }

    String clip(String line) =>
        line.length > maxLineLength ? '${line.substring(0, maxLineLength)}…' : line;

    final hits = <String>[];
    final d2 = _dur2Lines ?? const [];
    for (var i = 0; i < d2.length && hits.length < maxLines; i++) {
      if (i == 0) continue;
      final line = d2[i];
      if (matches(line)) hits.add('[DUR2-노인주의] ${clip(line)}');
    }

    final d1 = _dur1Lines ?? const [];
    for (var i = 0; i < d1.length && hits.length < maxLines; i++) {
      if (i == 0) continue;
      final line = d1[i];
      if (matches(line)) hits.add('[DUR1-병용금기] ${clip(line)}');
    }

    if (hits.isEmpty) {
      return '(DUR 로컬 검색: 일치 행 없음 · 토큰: ${tokens.take(6).join(", ")})';
    }
    return hits.join('\n');
  }
}
