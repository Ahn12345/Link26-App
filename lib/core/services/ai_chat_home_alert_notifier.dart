import 'package:flutter/foundation.dart';

import 'package:link26_app/core/database/home_notification_repository.dart';

/// AI 이미지 답변 완료 등 — DB에 쌓고, 홈 배너는 **가장 최근 미확인** 건을 표시합니다.
final class AiChatHomeAlertNotifier extends ChangeNotifier {
  AiChatHomeAlertNotifier._();
  static final AiChatHomeAlertNotifier instance = AiChatHomeAlertNotifier._();

  int? _bannerId;
  String _title = '';
  String _preview = '';
  DateTime? _at;
  bool _visible = false;

  bool get visible => _visible;
  int? get bannerId => _bannerId;
  String get title => _title;
  String get preview => _preview;
  DateTime? get at => _at;

  /// DB에 저장한 뒤 배너를 최신 미읽음 기준으로 갱신합니다.
  Future<void> onNewAiChatImageReply({
    required String title,
    required String previewText,
  }) async {
    var p = previewText.trim();
    if (p.length > 120) p = '${p.substring(0, 120)}…';
    await HomeNotificationRepository.insertAiChatImageReply(
      title: title,
      preview: p,
    );
    await refreshBannerFromDb();
  }

  Future<void> refreshBannerFromDb() async {
    final row = await HomeNotificationRepository.latestUnreadAiChat();
    if (row == null) {
      _visible = false;
      _bannerId = null;
      _title = '';
      _preview = '';
      _at = null;
      notifyListeners();
      return;
    }
    _bannerId = row.id;
    _title = row.title;
    _preview = row.preview;
    _at = DateTime.fromMillisecondsSinceEpoch(row.createdAtMs);
    _visible = true;
    notifyListeners();
  }

  /// 홈 카드 닫기 — 해당 알림을 읽음 처리 후 다음 미읽음이 있으면 표시.
  Future<void> dismiss() async {
    final id = _bannerId;
    if (id != null) {
      await HomeNotificationRepository.markRead(id);
    }
    await refreshBannerFromDb();
  }
}
