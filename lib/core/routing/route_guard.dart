import 'app_routes.dart';

/// 인증이 필요한 경로 (추후 세션·토큰과 연동).
bool requiresAuth(String routeName) {
  const protected = {
    AppRoutes.home,
    AppRoutes.aiChat,
    AppRoutes.familyVoice,
    AppRoutes.familyProfiles,
    AppRoutes.pushSettings,
    AppRoutes.homeLayout,
    AppRoutes.medicineGuide,
    AppRoutes.search,
    AppRoutes.more,
    AppRoutes.settings,
  };
  return protected.contains(routeName);
}
