import 'dart:convert';

List<List<String>> mapDurCsvRow(String raw) {
  return const LineSplitter()
      .convert(raw)
      .map((l) => l.split(','))
      .toList();
}
