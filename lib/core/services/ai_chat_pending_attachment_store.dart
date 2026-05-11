import 'package:flutter/foundation.dart';

/// 클립으로 첨부한 이미지 — [MainShell] 탭 전환으로 AI 화면이 dispose 되어도 유지됩니다.
final class AiChatPendingAttachmentStore extends ChangeNotifier {
  AiChatPendingAttachmentStore._();
  static final AiChatPendingAttachmentStore instance =
      AiChatPendingAttachmentStore._();

  Uint8List? _bytes;
  String? _mime;

  Uint8List? get bytes => _bytes;
  String? get mime => _mime;

  bool get hasPending =>
      _bytes != null && _bytes!.isNotEmpty && (_mime ?? '').isNotEmpty;

  void setAttachment(Uint8List bytes, String mime) {
    _bytes = bytes;
    _mime = mime;
    notifyListeners();
  }

  void clear() {
    if (_bytes == null && (_mime == null || _mime!.isEmpty)) return;
    _bytes = null;
    _mime = null;
    notifyListeners();
  }
}
