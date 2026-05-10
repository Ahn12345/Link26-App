import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:link26_app/core/constants/storage_keys.dart';
import 'package:link26_app/core/theme/app_theme.dart';
import 'package:link26_app/features/ai_chat/ai_chat_screen.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';
import 'package:link26_app/features/auth/login/login_page.dart';
import 'package:link26_app/features/auth/signup/signup_page.dart';
import 'package:link26_app/features/family_profiles/family_profiles_screen.dart';
import 'package:link26_app/features/family_voice/family_voice_screen.dart';
import 'package:link26_app/features/home/alerts_list_screen.dart';
import 'package:link26_app/features/home_layout/home_layout_screen.dart';
import 'package:link26_app/features/medicine/medicine_screen.dart';
import 'package:link26_app/features/medicine_guide/medicine_guide_screen.dart';
import 'package:link26_app/features/more/more_screen.dart';
import 'package:link26_app/features/push_settings/push_settings_screen.dart';
import 'package:link26_app/features/search/pill_search_screen.dart';
import 'package:link26_app/features/search/search_screen.dart';
import 'package:link26_app/features/settings/emergency_contact_screen.dart';
import 'package:link26_app/features/settings/settings_screen.dart';
import 'package:link26_app/features/shell/main_shell.dart';

class Link26App extends StatefulWidget {
  const Link26App({super.key});

  static Link26AppState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<Link26AppState>();

  @override
  State<Link26App> createState() => Link26AppState();
}

class Link26AppState extends State<Link26App> {
  Locale? _localeOverride;
  double _textScale = 1.0;

  double get currentTextScale => _textScale;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final code = p.getString(StorageKeys.localeOverride);
      final scale = p.getDouble(StorageKeys.textScaleFactor);
      if (!mounted) return;
      setState(() {
        if (code == null || code.isEmpty) {
          _localeOverride = null;
        } else {
          _localeOverride = Locale(code);
        }
        final s = (scale == null || scale <= 0) ? 1.0 : scale;
        _textScale = s.clamp(0.85, 1.35);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localeOverride = null;
        _textScale = 1.0;
      });
    }
  }

  /// null = follow system + [localeResolutionCallback].
  Future<void> setLocaleOverride(Locale? locale) async {
    final p = await SharedPreferences.getInstance();
    if (locale == null) {
      await p.remove(StorageKeys.localeOverride);
    } else {
      await p.setString(StorageKeys.localeOverride, locale.languageCode);
    }
    if (mounted) {
      setState(() => _localeOverride = locale);
    }
  }

  Future<void> setTextScaleFactor(double value) async {
    final clamped = value.clamp(0.85, 1.35);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(StorageKeys.textScaleFactor, clamped);
    if (mounted) {
      setState(() => _textScale = clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _localeOverride,
      title: 'Link App',
      theme: AppTheme.light,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.maybeOf(context) ??
            MediaQueryData.fromView(View.of(context));
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(_textScale)),
          child: child,
        );
      },
      home: const AuthWelcomeScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        if (locale != null) {
          for (final l in supported) {
            if (l.languageCode == locale.languageCode) {
              return l;
            }
          }
        }
        // 시스템 로케일이 없거나 미지원일 때 기본은 한국어(목업·스토어 기준).
        return const Locale('ko');
      },
      routes: {
        MainShell.routeName: (_) => const MainShell(),
        AuthWelcomeScreen.routeName: (_) => const AuthWelcomeScreen(),
        LoginPage.routeName: (_) => const LoginPage(),
        SignupPage.routeName: (_) => const SignupPage(),
        AiChatScreen.routeName: (_) => const AiChatScreen(),
        FamilyVoiceScreen.routeName: (_) => const FamilyVoiceScreen(),
        FamilyProfilesScreen.routeName: (_) => const FamilyProfilesScreen(),
        PushSettingsScreen.routeName: (_) => const PushSettingsScreen(),
        HomeLayoutScreen.routeName: (_) => const HomeLayoutScreen(),
        MedicineGuideScreen.routeName: (_) => const MedicineGuideScreen(),
        MedicineScreen.routeName: (_) => const MedicineScreen(),
        SearchScreen.routeName: (_) => const SearchScreen(),
        MoreScreen.routeName: (_) => const MoreScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        PillSearchScreen.routeName: (_) => const PillSearchScreen(),
        AlertsListScreen.routeName: (_) => const AlertsListScreen(),
        EmergencyContactScreen.routeName: (_) => const EmergencyContactScreen(),
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
    );
  }
}
