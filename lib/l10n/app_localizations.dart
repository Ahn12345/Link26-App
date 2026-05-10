import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

/// `flutter gen-l10n` ??? ??? API.
/// ARB ??: ???? ?? [l10n/].
/// (???? `flutter gen-l10n`? ???? ??? ?? ???? ???? ???.)
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(
      instance != null,
      'AppLocalizations.of() called with a context that does not contain AppLocalizations.',
    );
    return instance!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  String get appTitle;
  String get homeTitle;
  String get familyVoiceTitle;
  String get familyVoiceSubtitle;
  String get familyProfilesTitle;
  String get familyProfilesSubtitle;
  String get pushSettingsTitle;
  String get pushSettingsSubtitle;
  String get homeLayoutTitle;
  String get homeLayoutSubtitle;
  String get medicineGuideTitle;
  String get medicineGuideSubtitle;
  String get searchTitle;
  String get moreTitle;
  String get login;
  String get signup;
  String get authWelcomeSubtitle;
  String get continueCta;
  String get loginEmailLabel;
  String get loginPasswordLabel;
  String get loginFieldsRequired;
  String get signOut;
  String get homeLandingHint;
  String get moreMenuSectionTitle;
  String get medicineGuideIntro;
  String get medicineGuideMaxDoses;
  String get familyVoiceStub;
  String get familyProfilesStub;
  String get pushStub;
  String get homeLayoutHint;
  String get searchStub;
  String get moreStub;
  String get save;
  String get reload;
  String get activeProfile;
  String get addProfile;
  String get language;
  String get languageSystem;
  String get languageEnglish;
  String get languageKorean;
  String get recordVoiceImport;
  String get aiChatTitle;
  String get aiChatSubtitle;
  String get aiSymptomInputLabel;
  String get aiPrimaryAnswerButton;
  String get aiOcrInputLabel;
  String get aiOcrInputHint;
  String get aiAnalyzeImageButton;
  String get aiChatBrandTitle;
  String get aiChatQuotaResetHint;
  String get aiChatInputPlaceholder;
  String get aiChatDailyLimitReached;
  String get aiChatReplyError;
  String get aiChatDisclaimerShort;
  String get aiChatCameraUserMessage;
  String get aiChatCameraReplyStub;
  String get aiChatWelcomeIntro;
  String get aiChatWelcomeUploadHint;
  String get aiChatWelcomeTipEmoji;
  String get aiChatWelcomeTipTitle;
  String get aiChatWelcomeTipList;
  String get settingsTitle;
  String get settingsSubtitle;
  String get settingsTextSize;
  String get medicineCatalogTitle;
  String get medicineCatalogSubtitle;
  String get medicineCatalogTooltip;
  String get medicineCatalogEmpty;
  String get homeTodayAlertsTitle;
  String get homeTodayAlertsViewAll;
  String get homeMyMedicinesTitle;
  String get homeAddMedicine;
  String get homeNoMedicinesYet;
  String get alertsScreenTitle;
  String get alertItemWater;
  String get alertItemVitamin;
  String get alertItemWalk;
  String get pillSearchTitle;
  String get pillSearchLabel;
  String get pillSearchHint;
  String get pillSearchAdded;
  String get settingsEmergencyContact;
  String get settingsEmergencyContactSubtitle;
  String get settingsFamilyAddEntry;
  String get emergencyContactStub;
  String get emergencyCallPlaceholder;
  String get emergencyCallAction;
  String get monthlyHiraTitle;
  String get monthlyHiraBody;
  String get monthlyHiraPrimaryAction;
  String get monthlyHiraSecondTitle;
  String get monthlyHiraSecondHint;
  String get monthlyHiraComplete;
  String get later;
  String get loginFailed;
  String get signupEmailTaken;
  String get signupNameLabel;
  String get socialLoginComingSoon;
  String get socialLoginGoogle;
  String get socialLoginApple;
  String get loginDividerEmail;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
