import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';

/// `lib/data/DUR1`, `DUR2` CSV 에서 사용자 입력과 겹치는 행만 뽑아 프롬프트용으로 넣습니다.
/// (전체 CSV를 Gemini에 넣지 않음)
///
/// 대용량 CSV의 UTF-8 디코드·줄 분리는 [Isolate.run]으로 메인 isolate의 장시간 점유(ANR·심한 jank)를 피합니다.
abstract final class DurAssetContext {
  static const _dur1Asset =
      'lib/data/DUR1/DUR품목 누적데이터(병용금기)(2025년).csv';
  static const _dur2Asset =
      'lib/data/DUR2/DUR품목 누적데이터(노인주의)(2025년).csv';

  static List<String>? _dur1Lines;
  static List<String>? _dur2Lines;
  static Future<void>? _loadFuture;

  static List<String> _linesFromUtf8Bytes(Uint8List bytes) {
    return const LineSplitter().convert(utf8.decode(bytes));
  }

  static Future<List<String>> _loadDurLines(String assetKey) async {
    try {
      final bd = await rootBundle.load(assetKey);
      final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
      return Isolate.run(() => _linesFromUtf8Bytes(bytes));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _ensureLoaded() async {
    if (_dur1Lines != null && _dur2Lines != null) return;
    _loadFuture ??= () async {
      final results = await Future.wait([
        _loadDurLines(_dur1Asset),
        _loadDurLines(_dur2Asset),
      ]);
      _dur1Lines = results[0];
      _dur2Lines = results[1];
    }();
    await _loadFuture;
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
