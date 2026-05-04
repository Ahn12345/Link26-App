import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1] / "lib"


def snake_to_pascal(s: str) -> str:
    parts = s.replace(".dart", "").split("_")
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def main() -> None:
    for p in sorted(ROOT.rglob("*.dart")):
        try:
            t = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if "TODO: structure placeholder" not in t:
            continue
        rel = p.relative_to(ROOT).as_posix()
        if rel == "features/settings/settings_screen.dart":
            continue
        name = p.stem
        if rel.startswith("DB/models/"):
            cls = snake_to_pascal(name)
            body = f"class {cls} {{\n  const {cls}();\n}}\n"
        elif rel.startswith("DB/repositories/"):
            cls = snake_to_pascal(name)
            body = (
                "import '../../core/domain/result.dart';\n\n"
                f"abstract class {cls} {{\n  Future<Result<void>> ping();\n}}\n"
            )
        elif "DB/local" in rel:
            cls = snake_to_pascal(name)
            body = f"// {rel}\nclass {cls} {{\n}}\n"
        elif rel.startswith("data/parsers/"):
            if name == "dur_csv_parser":
                fn = "parseDurCsvLines"
            elif name == "dur_record_mapper":
                fn = "mapDurCsvRow"
            else:
                fn = "normalizeMedicineCsvLine"
            body = (
                "import 'dart:convert';\n\n"
                f"List<List<String>> {fn}(String raw) {{\n"
                "  return const LineSplitter()\n"
                "      .convert(raw)\n"
                "      .map((l) => l.split(','))\n"
                "      .toList();\n"
                "}\n"
            )
        elif rel.startswith("core/state/"):
            cls = snake_to_pascal(name)
            body = (
                "import 'package:flutter/foundation.dart';\n\n"
                f"class {cls} extends ChangeNotifier {{\n"
                "  void bump() => notifyListeners();\n"
                "}\n"
            )
        elif rel.endswith("_state.dart") and "features" in rel:
            cls = snake_to_pascal(name)
            body = f"class {cls} {{\n  const {cls}();\n}}\n"
        elif rel.endswith("_controller.dart") and "features" in rel:
            cls = snake_to_pascal(name)
            body = (
                "import 'package:flutter/foundation.dart';\n\n"
                f"class {cls} extends ChangeNotifier {{}}\n"
            )
        elif "features/" in rel and ("/ui/" in rel or rel.endswith("_screen.dart")):
            cls = snake_to_pascal(name)
            body = (
                "import 'package:flutter/material.dart';\n\n"
                f"class {cls} extends StatelessWidget {{\n"
                f"  const {cls}({{super.key}});\n\n"
                "  @override\n"
                "  Widget build(BuildContext context) {\n"
                "    return Scaffold(\n"
                f"      appBar: AppBar(title: Text('{name}')),\n"
                "      body: const Center(child: Text('TODO UI')),\n"
                "    );\n"
                "  }\n"
                "}\n"
            )
        else:
            body = f"// {rel}\nvoid {name}Init() {{}}\n"
        p.write_text(body, encoding="utf-8")
    print("filled placeholders")


if __name__ == "__main__":
    main()
