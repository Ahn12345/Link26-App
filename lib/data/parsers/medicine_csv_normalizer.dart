import 'dart:convert';

List<List<String>> normalizeMedicineCsvLine(String raw) {
  return const LineSplitter()
      .convert(raw)
      .map((l) => l.split(','))
      .toList();
}
