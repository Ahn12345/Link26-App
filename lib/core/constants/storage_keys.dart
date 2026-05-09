/// SharedPreferences 등 로컬 저장 키.
abstract final class StorageKeys {
  static const localeOverride = 'app_locale_override_v1';
  static const textScaleFactor = 'app_text_scale_factor_v1';
  static const sessionSignedInV1 = 'session_signed_in_v1';
  /// `yyyy-MM` of last completed monthly HIRA easy-auth (25일 플로우).
  static const hiraMonthlyAuthMonth = 'hira_monthly_auth_month_v1';
  static const localMyMedicinesJson = 'local_my_medicines_json_v1';
}
