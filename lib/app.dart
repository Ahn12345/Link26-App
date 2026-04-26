import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login/login_page.dart';
import 'features/auth/signup/signup_page.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/family_profiles/family_profiles_screen.dart';
import 'features/family_voice/family_voice_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home_layout/home_layout_screen.dart';
import 'features/medicine_guide/medicine_guide_screen.dart';
import 'features/more/more_screen.dart';
import 'features/push_settings/push_settings_screen.dart';
import 'features/search/search_screen.dart';
import 'features/splash/splash_screen.dart';

const _localePrefKey = 'app_locale_override_v1';

class LinkApp extends StatefulWidget {
  const LinkApp({super.key});

  static LinkAppState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<LinkAppState>();

  @override
  State<LinkApp> createState() => LinkAppState();
}

class LinkAppState extends State<LinkApp> {
  Locale? _localeOverride;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_localePrefKey);
    if (!mounted) return;
    setState(() {
      if (code == null || code.isEmpty) {
        _localeOverride = null;
      } else {
        _localeOverride = Locale(code);
      }
      _ready = true;
    });
  }

  /// null = follow system + [localeResolutionCallback].
  Future<void> setLocaleOverride(Locale? locale) async {
    final p = await SharedPreferences.getInstance();
    if (locale == null) {
      await p.remove(_localePrefKey);
    } else {
      await p.setString(_localePrefKey, locale.languageCode);
    }
    if (mounted) {
      setState(() => _localeOverride = locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      locale: _localeOverride,
      title: 'Link App',
      theme: AppTheme.light,
      initialRoute: SplashScreen.routeName,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return const Locale('en');
        for (final l in supported) {
          if (l.languageCode == locale.languageCode) {
            return l;
          }
        }
        return const Locale('en');
      },
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        LoginPage.routeName: (_) => const LoginPage(),
        SignupPage.routeName: (_) => const SignupPage(),
        AiChatScreen.routeName: (_) => const AiChatScreen(),
        FamilyVoiceScreen.routeName: (_) => const FamilyVoiceScreen(),
        FamilyProfilesScreen.routeName: (_) => const FamilyProfilesScreen(),
        PushSettingsScreen.routeName: (_) => const PushSettingsScreen(),
        HomeLayoutScreen.routeName: (_) => const HomeLayoutScreen(),
        MedicineGuideScreen.routeName: (_) => const MedicineGuideScreen(),
        SearchScreen.routeName: (_) => const SearchScreen(),
        MoreScreen.routeName: (_) => const MoreScreen(),
      },
    );
  }
}
