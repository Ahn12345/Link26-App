import 'package:shared_preferences/shared_preferences.dart';

import 'package:link26_app/core/constants/storage_keys.dart';

/// AI 채팅 **접속 시각** 로컬 기록.
///
/// 이후 서버·로컬 DB에 `user_id`, `session_id`, `accessed_at` 등을 넣을 때
/// [touchAccess]에서 저장한 [DateTime]을 함께 전송하면 됩니다.
class AiChatSessionStore {
  AiChatSessionStore._();

  /// 접속 시각을 갱신하고, 첫 AI 말풍선에 표시할 라벨용 시각을 돌려줍니다.
  static Future<DateTime> touchAccess() async {
    final now = DateTime.now();
    final p = await SharedPreferences.getInstance();
    await p.setInt(StorageKeys.aiChatLastAccessMs, now.millisecondsSinceEpoch);
    return now;
  }

  /// 마지막 저장된 접속 시각(없으면 null).
  static Future<DateTime?> loadLastAccess() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(StorageKeys.aiChatLastAccessMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// `오후 10:48` 형식 (시안과 동일한 한국어 오전/오후 표기).
  static String formatAccessLabel(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final ap = h < 12 ? '오전' : '오후';
    final hh12 = h <= 12 ? (h == 0 ? 12 : h) : h - 12;
    final mm = m.toString().padLeft(2, '0');
    return '$ap $hh12:$mm';
  }
}
