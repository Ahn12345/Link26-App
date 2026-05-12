import 'dart:convert';

import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';

/// AI 채팅(약·이미지) 보조: BFF `GET /v1/public/easy-drug` → 식약처 e약은요 요약을 프롬프트에 넣습니다.
abstract final class EasyDrugChatContext {
  static const int _maxItemNameLen = 48;
  static const int _efcyMaxChars = 320;

  /// 사용자 문장에서 검색어 후보를 뽑아 e약은요를 한 번 조회합니다.
  static Future<String> buildSnippetForUserText(String userText) async {
    final q = _queryFromUserText(userText);
    if (q == null) {
      return '(e약은요: 질문에서 약 이름 검색어를 추출하지 못함 — 약 이름을 텍스트로 적어 주세요)';
    }
    return _fetchAndFormat(q);
  }

  /// 1차 JSON의 `names_guessed` 등으로 추가 조회(이미지 분석 후 약명 후보용).
  static Future<String> buildSnippetForNames(List<String> names) async {
    if (names.isEmpty) return '';
    if (!Link26BffIntegrationsClient.canCall) {
      return '(e약은요: NHIS_BASE_URL 없음)';
    }
    final buf = StringBuffer();
    for (final raw in names.take(3)) {
      final n = raw.trim();
      if (n.length < 2) continue;
      final clipped = n.length > _maxItemNameLen ? n.substring(0, _maxItemNameLen) : n;
      try {
        final line = await _fetchAndFormat(clipped);
        if (line.isNotEmpty) buf.writeln(line);
      } catch (_) {}
    }
    final s = buf.toString().trim();
    if (s.isEmpty) return '';
    return '[e약은요·추가 발췌 (후보명 기준)]\n$s';
  }

  static String? _queryFromUserText(String userText) {
    var s = userText.trim();
    if (s.isEmpty) return null;
    var line = s.split(RegExp(r'[\r\n]+')).first.trim();
    if (line.length > _maxItemNameLen) {
      line = line.substring(0, _maxItemNameLen);
    }
    if (line.length < 2) return null;
    return line;
  }

  static Future<String> _fetchAndFormat(String itemName) async {
    if (!Link26BffIntegrationsClient.canCall) {
      return '(e약은요: BFF 미연결 — NHIS_BASE_URL·공공데이터 serviceKey 확인)';
    }
    final res = await Link26BffIntegrationsClient.searchEasyDrug(
      itemName: itemName,
      numOfRows: 4,
    );
    return _formatResponse(res, itemName);
  }

  static String _formatResponse(Map<String, dynamic>? res, String queriedAs) {
    if (res == null) return '(e약은요: 응답 없음)';
    final data = res['data'];
    final rows = _normalizeItems(data);
    if (rows.isEmpty) {
      return '(e약은요: "$queriedAs" 검색 결과 0건)';
    }
    final buf = StringBuffer();
    buf.writeln('(검색어: $queriedAs)');
    for (var i = 0; i < rows.length && i < 3; i++) {
      final row = rows[i];
      final name = row['itemName'] ?? row['itemSeq'] ?? '—';
      var efcy = (row['efcyQesitm'] ?? '').toString().trim();
      if (efcy.length > _efcyMaxChars) {
        efcy = '${efcy.substring(0, _efcyMaxChars)}…';
      }
      final use = (row['useMethodQesitm'] ?? '').toString().trim();
      buf.writeln('- $name');
      if (efcy.isNotEmpty) buf.writeln('  효능: $efcy');
      if (use.isNotEmpty && use.length <= 200) buf.writeln('  용법: $use');
    }
    return buf.toString().trim();
  }

  static List<Map<String, String>> _normalizeItems(dynamic root) {
    if (root is! Map) return [];
    final inner = (root['response'] is Map ? (root['response'] as Map)['body'] : null) ??
        root['body'];
    if (inner is! Map) return [];
    var items = inner['items'];
    if (items == null) return [];
    final list = items is List ? items : [items];
    final out = <Map<String, String>>[];
    for (final entry in list) {
      if (entry is Map && entry['item'] is Map) {
        out.add(Map<String, String>.from(
          (entry['item'] as Map).map((k, v) => MapEntry('$k', '$v')),
        ));
      } else if (entry is Map) {
        out.add(Map<String, String>.from(
          entry.map((k, v) => MapEntry('$k', '$v')),
        ));
      }
    }
    return out.where((m) => m.isNotEmpty).toList();
  }

  /// [primaryRaw] JSON 블록에서 `names_guessed` 배열 추출 (실패 시 빈 목록).
  static List<String> parseNamesGuessedFromPrimaryJson(String primaryRaw) {
    final s = primaryRaw.trim();
    if (s.isEmpty) return [];
    final i = s.indexOf('{');
    final j = s.lastIndexOf('}');
    if (i < 0 || j <= i) return [];
    try {
      final map = jsonDecode(s.substring(i, j + 1));
      if (map is! Map) return [];
      final ng = map['names_guessed'];
      if (ng is! List) return [];
      return ng
          .map((e) => '$e'.trim())
          .where((x) => x.length >= 2 && x.length <= _maxItemNameLen)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
