// link26_image_assets.xml / ImageAssets 와 동일한 파일명으로 PNG 생성.
// 최종 시안 PNG로 교체하기 전까지 빌드·런처 아이콘 경로가 깨지지 않게 합니다.
// 실행: dart run tool/gen_image_assets.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _accentR = 0x00;
const _accentG = 0x47;
const _accentB = 0xAB;

const _ids = <String>[
  'applogo',
  'logo',
  'login',
  'signup',
  'home',
  'aichat',
  'setting',
  'pillsearch',
  'emergencycall',
  'familyadd',
  'simplelogin1',
  'simplelogin2',
];

void main() {
  final root = Directory.current;
  final out = Directory.fromUri(root.uri.resolve('assets/images/'));
  if (!out.existsSync()) {
    out.createSync(recursive: true);
  }

  for (var i = 0; i < _ids.length; i++) {
    final id = _ids[i];
    final isLauncher = id == 'applogo';
    final w = isLauncher ? 512 : 1080;
    final h = isLauncher ? 512 : 720;
    final image = img.Image(width: w, height: h);
    final tint = 8 * i;
    img.fill(
      image,
      color: img.ColorRgb8(
        (0xE4 + tint).clamp(0, 255),
        (0xEE - tint ~/ 2).clamp(0, 255),
        (0xF8).clamp(0, 255),
      ),
    );
    final barH = (h / 10).round().clamp(24, 120);
    img.fillRect(
      image,
      x1: 0,
      y1: h - barH,
      x2: w,
      y2: h,
      color: img.ColorRgb8(_accentR, _accentG, _accentB),
    );
    if (isLauncher) {
      final cx = w ~/ 2;
      final cy = h ~/ 2;
      final r = (w * 0.28).round();
      img.fillCircle(
        image,
        x: cx,
        y: cy,
        radius: r,
        color: img.ColorRgb8(255, 255, 255),
      );
      img.fillCircle(
        image,
        x: cx,
        y: cy,
        radius: (r * 0.55).round(),
        color: img.ColorRgb8(_accentR, _accentG, _accentB),
      );
    }
    final path = '${out.path}${Platform.pathSeparator}$id.png';
    File(path).writeAsBytesSync(img.encodePng(image), flush: true);
    stdout.writeln('wrote $path');
  }
  stdout.writeln('done: ${_ids.length} files');
  stdout.writeln('Next: dart run tool/sync_image_specs_from_assets.dart');
}
