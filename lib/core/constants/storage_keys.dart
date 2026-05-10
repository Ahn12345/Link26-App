/// SharedPreferences 등 로컬 저장 키.
abstract final class StorageKeys {
  static const localeOverride = 'app_locale_override_v1';
  static const textScaleFactor = 'app_text_scale_factor_v1';
  static const sessionSignedInV1 = 'session_signed_in_v1';
  /// `yyyy-MM` of last completed monthly HIRA easy-auth (25일 플로우).
  static const hiraMonthlyAuthMonth = 'hira_monthly_auth_month_v1';
  static const localMyMedicinesJson = 'local_my_medicines_json_v1';

  /// AI 채팅 탭 마지막 접속 시각(epoch ms). 서버/DB 연동 시 동일 시점을 동기화하면 됨.
  static const aiChatLastAccessMs = 'ai_chat_last_access_ms_v1';
}
