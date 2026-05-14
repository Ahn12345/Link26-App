import 'dart:convert';

/// BFF `tool/link26_bff_codef.dart` 의 dotenv 보조 파싱 — 단위 테스트와 도구 코드가 공유합니다.
abstract final class BffDotenvLineScan {
  static String stripUtf8Bom(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.codeUnitAt(0) == 0xFEFF) return raw.substring(1);
    return raw;
  }

  static String stripQuotes(String v) {
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      return v.substring(1, v.length - 1).trim();
    }
    return v;
  }

  /// 일반 [Map] 병합이 놓칠 때 `TILKO_API_KEY=` 한 줄만 직접 찾습니다.
  static String? scanTilkoApiKeyLineByLine(String raw) {
    final text = stripUtf8Bom(raw);
    for (var line in LineSplitter.split(text)) {
      line = line.trimRight();
      if (line.isEmpty) continue;
      final left = line.trimLeft();
      if (left.startsWith('#')) continue;
      final eq = left.indexOf('=');
      if (eq <= 0) continue;
      final key = left.substring(0, eq).trim();
      if (key != 'TILKO_API_KEY') continue;
      var val = left.substring(eq + 1).trim();
      val = stripQuotes(val);
      final hash = val.indexOf(' #');
      if (hash > 0) val = val.substring(0, hash).trim();
      if (val.isNotEmpty) return val;
    }
    return null;
  }
}
