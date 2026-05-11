import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

/// `assets/design/screens/*.xml`, `assets/design/png/*.xml` 인덱스를 런타임에 로드해
/// 카탈로그별 **실제 에셋 경로**·화면 메타를 제공합니다. (`ImageAssets` 폴백 유지)
///
/// - 인덱스: [kScreenIndexAsset], [kPngIndexAsset]
/// - [load]는 [main]에서 `runApp` 전에 한 번 호출하는 것을 권장합니다.
abstract final class Link26DesignCatalog {
  static const kScreenIndexAsset = 'assets/design/screens/link26_screen_index.xml';
  static const kPngIndexAsset = 'assets/design/png/link26_png_index.xml';
  static const kScreenSpecPrefix = 'assets/design/screens/';
  static const kPngSpecPrefix = 'assets/design/png/';

  static final Map<String, String> _pngAssetByCatalogId = {};
  static final Map<String, Link26ScreenCatalogEntry> _screenByCatalogId = {};
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  /// PNG 스펙 `<source path="assets/images/..."/>` — 없으면 [fallback].
  static String heroAssetPath(String catalogId, String fallback) =>
      _pngAssetByCatalogId[catalogId] ?? fallback;

  static Link26ScreenCatalogEntry? screenEntry(String catalogId) =>
      _screenByCatalogId[catalogId];

  static Iterable<String> get pngCatalogIds => _pngAssetByCatalogId.keys;

  static Iterable<String> get screenCatalogIds => _screenByCatalogId.keys;

  /// 인덱스 + 각 스펙 XML을 읽어 맵을 채웁니다. 실패 시 로그만 남기고 [ImageAssets] 폴백에 의존합니다.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      await Future.wait([
        _loadPngBranch(),
        _loadScreenBranch(),
      ]);
      _loaded = true;
      if (kDebugMode) {
        debugPrint(
          'Link26DesignCatalog: png=${_pngAssetByCatalogId.length} '
          'screens=${_screenByCatalogId.length}',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Link26DesignCatalog: load failed (fallback ImageAssets): $e');
        debugPrint('$st');
      }
      _loaded = true;
    }
  }

  static Future<void> _loadPngBranch() async {
    final raw = await rootBundle.loadString(kPngIndexAsset);
    final doc = XmlDocument.parse(raw);
    final root = doc.rootElement;
    final futures = <Future<void>>[];
    for (final el in root.findElements('entry')) {
      final id = el.getAttribute('catalogId')?.trim();
      final spec = el.getAttribute('spec')?.trim();
      if (id == null || id.isEmpty || spec == null || spec.isEmpty) continue;
      futures.add(_loadOnePngSpec(id, '$kPngSpecPrefix$spec'));
    }
    await Future.wait(futures);
  }

  static Future<void> _loadOnePngSpec(String catalogId, String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final doc = XmlDocument.parse(raw);
      final root = doc.rootElement;
      if (root.localName != 'link26-png-spec') return;
      final path = _firstAttrPath(root, 'source', 'path');
      if (path != null && path.isNotEmpty) {
        _pngAssetByCatalogId[catalogId] = path;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Link26DesignCatalog: skip png spec $assetPath: $e');
      }
    }
  }

  static Future<void> _loadScreenBranch() async {
    final raw = await rootBundle.loadString(kScreenIndexAsset);
    final doc = XmlDocument.parse(raw);
    final root = doc.rootElement;
    final futures = <Future<void>>[];
    for (final el in root.findElements('entry')) {
      final id = el.getAttribute('catalogId')?.trim();
      final spec = el.getAttribute('spec')?.trim();
      if (id == null || id.isEmpty || spec == null || spec.isEmpty) continue;
      futures.add(_loadOneScreenSpec(id, '$kScreenSpecPrefix$spec'));
    }
    await Future.wait(futures);
  }

  static Future<void> _loadOneScreenSpec(String catalogId, String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final doc = XmlDocument.parse(raw);
      final root = doc.rootElement;
      if (root.localName != 'link26-screen-spec') return;
      final title = root.getAttribute('title');
      final kind = root.getAttribute('kind');
      final hero = _firstElement(root, 'hero');
      final heroCatalogId = hero?.getAttribute('catalogId')?.trim();
      final heroFile = hero?.getAttribute('file')?.trim();
      final flutterEl = _firstElement(root, 'flutter');
      final flutterPath = flutterEl?.getAttribute('path');
      _screenByCatalogId[catalogId] = Link26ScreenCatalogEntry(
        catalogId: catalogId,
        title: title,
        kind: kind,
        heroCatalogId: heroCatalogId,
        heroFile: heroFile,
        flutterPath: flutterPath,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Link26DesignCatalog: skip screen spec $assetPath: $e');
      }
    }
  }

  static String? _firstAttrPath(XmlElement root, String tag, String attr) {
    for (final el in root.findElements(tag)) {
      final v = el.getAttribute(attr);
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static XmlElement? _firstElement(XmlElement root, String name) {
    for (final el in root.findElements(name)) {
      return el;
    }
    return null;
  }
}

class Link26ScreenCatalogEntry {
  const Link26ScreenCatalogEntry({
    required this.catalogId,
    this.title,
    this.kind,
    this.heroCatalogId,
    this.heroFile,
    this.flutterPath,
  });

  final String catalogId;
  final String? title;
  final String? kind;
  final String? heroCatalogId;
  final String? heroFile;
  final String? flutterPath;
}
