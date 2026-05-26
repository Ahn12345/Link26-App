import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Gemini 업로드용 — 해상도·용량을 줄여 타임아웃을 줄입니다.
abstract final class PrescriptionImagePrepare {
  static const int _maxEdge = 1600;

  static Uint8List forVisionApi(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final w = decoded.width;
      final h = decoded.height;
      if (w <= _maxEdge && h <= _maxEdge && bytes.length < 2 * 1024 * 1024) {
        return bytes;
      }
      final scale = _maxEdge / (w > h ? w : h);
      final resized = img.copyResize(
        decoded,
        width: (w * scale).round().clamp(1, _maxEdge),
        height: (h * scale).round().clamp(1, _maxEdge),
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 86));
    } catch (_) {
      return bytes;
    }
  }
}
