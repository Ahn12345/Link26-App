import 'package:flutter/material.dart';

import 'package:link26_app/features/ai_chat/ai_chat_screen.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';
import 'package:link26_app/features/auth/login/login_page.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';
import 'package:link26_app/features/family_profiles/family_profiles_screen.dart';
import 'package:link26_app/features/family_voice/family_voice_screen.dart';
import 'package:link26_app/features/home/alerts_list_screen.dart';
import 'package:link26_app/features/home_layout/home_layout_screen.dart';
import 'package:link26_app/features/medicine_guide/medicine_guide_screen.dart';
import 'package:link26_app/features/more/more_screen.dart';
import 'package:link26_app/features/push_settings/push_settings_screen.dart';
import 'package:link26_app/features/search/pill_search_screen.dart';
import 'package:link26_app/features/search/search_screen.dart';
import 'package:link26_app/features/settings/emergency_contact_screen.dart';
import 'package:link26_app/features/settings/settings_screen.dart';
import 'package:link26_app/features/shell/main_shell.dart';
import 'package:link26_app/features/splash/splash_screen.dart';
import 'app_routes.dart';

/// 중앙 라우트 테이블 (MaterialApp routes 대체용).
Map<String, WidgetBuilder> buildAppRoutes() {
  return {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.home: (_) => const MainShell(),
    AppRoutes.authWelcome: (_) => const AuthWelcomeScreen(),
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
    AppRoutes.pillSearch: (_) => const PillSearchScreen(),
    AppRoutes.alerts: (_) => const AlertsListScreen(),
    AppRoutes.emergencyContact: (_) => const EmergencyContactScreen(),
  };
}
