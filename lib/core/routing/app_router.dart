import 'package:flutter/material.dart';

import '../../features/ai_chat/ai_chat_screen.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/auth/signup/signup_page.dart';
import '../../features/family_profiles/family_profiles_screen.dart';
import '../../features/family_voice/family_voice_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home_layout/home_layout_screen.dart';
import '../../features/medicine_guide/medicine_guide_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/push_settings/push_settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';

/// 중앙 라우트 테이블 (MaterialApp routes 대체용).
Map<String, WidgetBuilder> buildAppRoutes() {
  return {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.home: (_) => const HomeScreen(),
    AppRoutes.login: (_) => const LoginPage(),
    AppRoutes.signup: (_) => const SignupPage(),
    AppRoutes.aiChat: (_) => const AiChatScreen(),
    AppRoutes.familyVoice: (_) => const FamilyVoiceScreen(),
    AppRoutes.familyProfiles: (_) => const FamilyProfilesScreen(),
    AppRoutes.pushSettings: (_) => const PushSettingsScreen(),
    AppRoutes.homeLayout: (_) => const HomeLayoutScreen(),
    AppRoutes.medicineGuide: (_) => const MedicineGuideScreen(),
    AppRoutes.search: (_) => const SearchScreen(),
    AppRoutes.more: (_) => const MoreScreen(),
    AppRoutes.settings: (_) => const SettingsScreen(),
  };
}
