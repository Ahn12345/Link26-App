// assets/images 의 PNG + link26_image_assets.xml 를 기준으로
// 1) assets/images/link26_image_production.xml 생성(제작 스냅샷)
// 2) assets/design/png/link26_png_<id>.xml 에 <measured/> 삽입·갱신
//
// 실행: dart run tool/sync_image_specs_from_assets.dart
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';

const _catalogPath = 'assets/images/link26_image_assets.xml';
const _productionPath = 'assets/images/link26_image_production.xml';
const _designPngDir = 'assets/design/png';

void main() {
  final root = Directory.current;
  final catalogFile = File.fromUri(root.uri.resolve(_catalogPath));
  if (!catalogFile.existsSync()) {
    stderr.writeln('missing $catalogFile');
    exit(1);
  }

  final catalogDoc = XmlDocument.parse(catalogFile.readAsStringSync());
  final images = catalogDoc.findAllElements('image').toList();
  final generatedAt = DateTime.now().toUtc().toIso8601String();

  final specRoot = XmlElement(XmlName('link26-image-production'));
  specRoot.setAttribute('version', '1');
  specRoot.setAttribute('generatedAt', generatedAt);
  specRoot.setAttribute(
    'catalog',
    'assets/images/link26_image_assets.xml',
  );

  for (final el in images) {
    final id = el.getAttribute('id');
    final file = el.getAttribute('file');
    final dartConst = el.getAttribute('dart-const');
    final usage = el.getAttribute('usage') ?? '';
    if (id == null || file == null || dartConst == null) continue;

    final pngPath = 'assets/images/$file';
    final absPng = File.fromUri(root.uri.resolve(pngPath));
    if (!absPng.existsSync()) {
      final miss = XmlElement(XmlName('missing'));
      miss.setAttribute('catalogId', id);
      miss.setAttribute('expectedPath', pngPath);
      specRoot.children.add(miss);
      specRoot.children.add(XmlText('\n  '));
      stderr.writeln('missing PNG: $pngPath');
      continue;
    }

    final bytes = absPng.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      stderr.writeln('decode failed: $pngPath');
      continue;
    }

    final w = decoded.width;
    final h = decoded.height;
    final byteLen = bytes.length;

    final assetEl = XmlElement(XmlName('asset'));
    assetEl.setAttribute('catalogId', id);
    assetEl.setAttribute('file', file);
    assetEl.setAttribute('dartConst', dartConst);
    assetEl.setAttribute('usage', usage);
    assetEl.setAttribute('path', pngPath);
    assetEl.setAttribute('intrinsicWidth', '$w');
    assetEl.setAttribute('intrinsicHeight', '$h');
    assetEl.setAttribute('bytesOnDisk', '$byteLen');
    assetEl.setAttribute('spec', '$_designPngDir/link26_png_$id.xml');
    specRoot.children.add(assetEl);
    specRoot.children.add(XmlText('\n  '));

    _upsertDesignSpec(
      root: root,
      catalogId: id,
      file: file,
      dartConst: dartConst,
      usage: usage,
      pngPath: pngPath,
      w: w,
      h: h,
      byteLen: byteLen,
      generatedAt: generatedAt,
    );
  }

  _appendUnlistedPngs(root, specRoot, images);

  final prodDoc = XmlDocument([
    XmlDeclaration([
      XmlAttribute(XmlName('version'), '1.0'),
      XmlAttribute(XmlName('encoding'), 'UTF-8'),
    ]),
    XmlText('\n'),
    XmlComment(
      ' link26_image_production.xml: assets/images PNG 실측. 수동 편집 금지. '
      'dart run tool/sync_image_specs_from_assets.dart ',
    ),
    XmlText('\n'),
    specRoot,
  ]);
  final outFile = File.fromUri(root.uri.resolve(_productionPath));
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    prodDoc.toXmlString(pretty: true, indent: '  ', newLine: '\n'),
  );
  stdout.writeln('wrote $_productionPath');
}

void _appendUnlistedPngs(
  Directory root,
  XmlElement specRoot,
  List<XmlElement> catalogImages,
) {
  final listed = catalogImages
      .map((e) => e.getAttribute('file'))
      .whereType<String>()
      .toSet();
  final dir = Directory.fromUri(root.uri.resolve('assets/images/'));
  if (!dir.existsSync()) return;
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.toLowerCase().endsWith('.png')) continue;
    final name = f.uri.pathSegments.last;
    if (listed.contains(name)) continue;
    final u = XmlElement(XmlName('unlisted'));
    u.setAttribute('file', name);
    u.setAttribute(
      'path',
      'assets/images/$name',
    );
    specRoot.children.add(u);
    specRoot.children.add(XmlText('\n  '));
    stderr.writeln('unlisted PNG (add to link26_image_assets.xml): $name');
  }
}

void _upsertDesignSpec({
  required Directory root,
  required String catalogId,
  required String file,
  required String dartConst,
  required String usage,
  required String pngPath,
  required int w,
  required int h,
  required int byteLen,
  required String generatedAt,
}) {
  final specRel = '$_designPngDir/link26_png_$catalogId.xml';
  final specFile = File.fromUri(root.uri.resolve(specRel));

  late final XmlDocument doc;
  late final XmlElement rootEl;

  if (specFile.existsSync()) {
    doc = XmlDocument.parse(specFile.readAsStringSync());
    rootEl = doc.rootElement;
    if (rootEl.name.local != 'link26-png-spec') {
      stderr.writeln('skip bad root in $specRel');
      return;
    }
  } else {
    doc = XmlDocument([]);
    rootEl = XmlElement(XmlName('link26-png-spec'));
    rootEl.setAttribute('version', '1');
    rootEl.setAttribute('catalogId', catalogId);
    rootEl.setAttribute('file', file);
    rootEl.setAttribute('dartConst', dartConst);
    doc.children.add(XmlDeclaration([
      XmlAttribute(XmlName('version'), '1.0'),
      XmlAttribute(XmlName('encoding'), 'UTF-8'),
    ]));
    doc.children.add(XmlText('\n'));
    doc.children.add(rootEl);
    rootEl.children.add(XmlText('\n  '));
    final sum = XmlElement(XmlName('summary'));
    sum.setAttribute('usage', usage);
    rootEl.children.add(sum);
    rootEl.children.add(XmlText('\n  '));
    final src = XmlElement(XmlName('source'));
    src.setAttribute('path', pngPath);
    rootEl.children.add(src);
    rootEl.children.add(XmlText('\n'));
  }

  for (final m in rootEl.findElements('measured').toList()) {
    m.remove();
  }

  final measured = XmlElement(XmlName('measured'));
  measured.setAttribute('intrinsicWidth', '$w');
  measured.setAttribute('intrinsicHeight', '$h');
  measured.setAttribute('bytesOnDisk', '$byteLen');
  measured.setAttribute('generatedAt', generatedAt);
  measured.setAttribute('path', pngPath);

  final sourceIdx = rootEl.children.indexWhere(
    (n) => n is XmlElement && n.name.local == 'source',
  );
  if (sourceIdx >= 0) {
    rootEl.children.insert(sourceIdx + 1, XmlText('\n  '));
    rootEl.children.insert(sourceIdx + 2, measured);
  } else {
    rootEl.children.insert(0, measured);
    rootEl.children.insert(1, XmlText('\n  '));
  }

  specFile.parent.createSync(recursive: true);
  specFile.writeAsStringSync(
    doc.toXmlString(pretty: true, indent: '  ', newLine: '\n'),
  );
  stdout.writeln('updated $specRel');
}
