import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/storage_keys.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login/login_page.dart';
import 'features/auth/signup/signup_page.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/family_profiles/family_profiles_screen.dart';
import 'features/family_voice/family_voice_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home_layout/home_layout_screen.dart';
import 'features/medicine/medicine_screen.dart';
import 'features/medicine_guide/medicine_guide_screen.dart';
import 'features/more/more_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/push_settings/push_settings_screen.dart';
import 'features/search/search_screen.dart';
import 'features/splash/splash_screen.dart';

class LinkApp extends StatefulWidget {
  const LinkApp({super.key});

  static LinkAppState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<LinkAppState>();

  @override
  State<LinkApp> createState() => LinkAppState();
}

class LinkAppState extends State<LinkApp> {
  Locale? _localeOverride;
  double _textScale = 1.0;
  bool _ready = false;

  double get currentTextScale => _textScale;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
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
      _ready = true;
    });
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
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      locale: _localeOverride,
      title: 'Link App',
      theme: AppTheme.light,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(_textScale)),
          child: child,
        );
      },
      initialRoute: SplashScreen.routeName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
        MedicineScreen.routeName: (_) => const MedicineScreen(),
        SearchScreen.routeName: (_) => const SearchScreen(),
        MoreScreen.routeName: (_) => const MoreScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}
