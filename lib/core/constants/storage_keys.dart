/// SharedPreferences 등 로컬 저장 키.
abstract final class StorageKeys {
  static const localeOverride = 'app_locale_override_v1';
  static const textScaleFactor = 'app_text_scale_factor_v1';
  static const sessionSignedInV1 = 'session_signed_in_v1';
  /// 로그인한 로컬 사용자 전화번호(숫자만). [AuthSession.signIn] 시 저장.
  static const sessionActivePhoneV1 = 'session_active_phone_v1';
  /// `yyyy-MM` of last completed monthly HIRA easy-auth (25일 플로우).
  static const hiraMonthlyAuthMonth = 'hira_monthly_auth_month_v1';
  static const localMyMedicinesJson = 'local_my_medicines_json_v1';

  /// 날짜(yyyy-MM-dd) → 해당 일에 복용 완료 처리한 약 이름 정규화 목록 JSON.
  static const doseReminderCompletedByDayV1 = 'dose_reminder_completed_by_day_v1';

  /// [Medicine] 목록 JSON (이름·용량·복용법·시간) — NHIS/BFF 동기화·수동 추가 병합.
  static const nhisSyncedMedicinesJsonV1 = 'nhis_synced_medicines_json_v1';

  /// AI 채팅 탭 마지막 접속 시각(epoch ms). 서버/DB 연동 시 동일 시점을 동기화하면 됨.
  static const aiChatLastAccessMs = 'ai_chat_last_access_ms_v1';

  /// 일일 질문 한도(04:00 로컬 기준일) — [aiChatQuotaDayV1] 과 쌍.
  static const aiChatQuotaDayV1 = 'ai_chat_quota_day_v1';
  static const aiChatQuotaUsedV1 = 'ai_chat_quota_used_v1';

  /// 직렬화된 말풍선 목록 JSON (탭 전환·앱 재시작 후 복원).
  static const aiChatMessagesJsonV1 = 'ai_chat_messages_json_v1';
}
