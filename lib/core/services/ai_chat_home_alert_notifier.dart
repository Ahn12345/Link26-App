import 'package:flutter/foundation.dart';

/// 이미지 포함 AI 답변이 완료되었을 때 홈 「오늘의 알림」 영역에 표시합니다.
final class AiChatHomeAlertNotifier extends ChangeNotifier {
  AiChatHomeAlertNotifier._();
  static final AiChatHomeAlertNotifier instance = AiChatHomeAlertNotifier._();

  String _title = '';
  String _preview = '';
  DateTime? _at;
  bool _visible = false;

  bool get visible => _visible;
  String get title => _title;
  String get preview => _preview;
  DateTime? get at => _at;

  void showImageReplyReady({
    required String title,
    required String previewText,
  }) {
    var p = previewText.trim();
    if (p.length > 120) p = '${p.substring(0, 120)}…';
    _title = title;
    _preview = p;
    _at = DateTime.now();
    _visible = true;
    notifyListeners();
  }

  void dismiss() {
    if (!_visible) return;
    _visible = false;
    _title = '';
    _preview = '';
    _at = null;
    notifyListeners();
  }
}
