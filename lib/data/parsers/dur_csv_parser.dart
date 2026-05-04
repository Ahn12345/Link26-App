import 'dart:convert';

List<List<String>> parseDurCsvLines(String raw) {
  return const LineSplitter()
      .convert(raw)
      .map((l) => l.split(','))
      .toList();
}
