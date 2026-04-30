import 'package:flutter/material.dart';

/// ARB?Ä ?ôÏùº ????`flutter gen-l10n` ?Ä???òÎèô ?†Ï?(OneDrive ?±Ïóê??ÏΩîÎìú?ùÏÑ± ?§Ìå® ???ÄÎπ?.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  static final Map<String, Map<String, String>> _m = {
    'en': {
      'appTitle': 'Link App',
      'homeTitle': 'Home',
      'familyVoiceTitle': 'Family voice alerts',
      'familyVoiceSubtitle':
          'Register voices for call-style reminders',
      'familyProfilesTitle': 'Family profiles',
      'familyProfilesSubtitle': 'Netflix-style household accounts',
      'pushSettingsTitle': 'Push notifications',
      'pushSettingsSubtitle': 'General alerts & channels',
      'homeLayoutTitle': 'Home screen layout',
      'homeLayoutSubtitle': 'Choose what appears on the main screen',
      'medicineGuideTitle': 'Medicine guide',
      'medicineGuideSubtitle':
          'How to take each medicine, daily limits, AI reset',
      'searchTitle': 'Search',
      'moreTitle': 'More',
      'login': 'Log in',
      'signup': 'Sign up',
      'medicineGuideIntro':
          'Each medicine type can show how often to take it. The app treats a ?úday??as starting at 04:00 local time for counters and AI context reset.',
      'medicineGuideMaxDoses':
          'The model allows up to 10 doses in that daily window (adjust per prescription in a future build).',
      'familyVoiceStub':
          'Voice recording and call-style playback will use OS permissions and secure storage.',
      'familyProfilesStub':
          'Switch profiles like Netflix; data can sync to a backend later.',
      'pushStub':
          'Enable categories here after Firebase Cloud Messaging (or equivalent) is configured.',
      'homeLayoutHint': 'Toggle blocks shown on the home screen.',
      'searchStub':
          'Medicine and content search ??connect to your data sources.',
      'moreStub': 'Settings and legal links ??expand as needed.',
      'save': 'Save',
      'activeProfile': 'Active profile',
      'addProfile': 'Add profile',
      'reload': 'Reload home',
      'language': 'Language',
      'languageSystem': 'System default',
      'languageEnglish': 'English',
      'languageKorean': 'Korean',
      'recordVoiceImport': 'Record / import',
      'aiChatTitle': 'AI Chat & Recognition',
      'aiChatSubtitle':
          'Analyze prescriptions/supplements and show traffic-light safety.',
      'aiSymptomInputLabel': 'Describe your symptoms',
      'aiPrimaryAnswerButton': 'Get clear first answer',
      'aiOcrInputLabel': 'Recognized text from image',
      'aiOcrInputHint': 'Paste OCR text from prescription or supplement label',
      'aiAnalyzeImageButton': 'Analyze image text',
    },
    'ko': {
      'appTitle': 'ÎßÅÌÅ¨ ??,
      'homeTitle': '??,
      'familyVoiceTitle': 'Í∞ÄÏ°?Î™©ÏÜåÎ¶??åÎ¶º',
      'familyVoiceSubtitle': '?ÑÌôî ?åÎ¶ºÏ≤òÎüº ?§Î¶¨??Í∞ÄÏ°??åÏÑ± ?±Î°ù',
      'familyProfilesTitle': 'Í∞ÄÏ°?Í≥ÑÏ†ï',
      'familyProfilesSubtitle': '?∑ÌîåÎ¶?ä§Ï≤òÎüº ?ÑÎ°ú???ÑÌôò',
      'pushSettingsTitle': '?∏Ïãú ?åÎ¶º',
      'pushSettingsSubtitle': '?ºÎ∞ò ?åÎ¶º¬∑Ï±ÑÎÑê ?§Ï†ï',
      'homeLayoutTitle': 'Î©îÏù∏ ?îÎ©¥ Íµ¨ÏÑ±',
      'homeLayoutSubtitle': 'Î©îÏù∏??Î≥¥Ïùº ?ïÎ≥¥ ?†ÌÉù',
      'medicineGuideTitle': '??Î≥µÏö© ?àÎÇ¥',
      'medicineGuideSubtitle':
          '??Ï¢ÖÎ•òÎ≥?Î∞©Î≤ï¬∑?üÏàò¬∑04??Í∏∞Ï? Ï¥àÍ∏∞??,
      'searchTitle': 'Í≤Ä??,
      'moreTitle': '?îÎ≥¥Í∏?,
      'login': 'Î°úÍ∑∏??,
      'signup': '?åÏõêÍ∞Ä??,
      'medicineGuideIntro':
          '??Ï¢ÖÎ•òÎ≥ÑÎ°ú Î≥µÏö© Ï£ºÍ∏∞¬∑Î∞©Î≤ï???àÎÇ¥?©Îãà?? Î≥µÏö© ?üÏàò ÏßëÍ≥Ñ?Ä AI Îß•ÎùΩ?Ä Îß§Ïùº 04:00(Î°úÏª¨)??Ï¥àÍ∏∞?îÎêò???òÌïòÎ£®‚Ä?Í∏∞Ï????ÅÎãà??',
      'medicineGuideMaxDoses':
          '?òÎ£® Ï∞ΩÏóê??ÏµúÎ? 10?åÍπåÏßÄ Î™®Îç∏???¥ÏùÑ ???àÏäµ?àÎã§(Ï≤òÎ∞©??ÎßûÍ≤å Ï∂îÌõÑ Ï°∞Ï†ï).',
      'familyVoiceStub':
          'Í∞ÄÏ°??åÏÑ± ?πÏùå¬∑?ÑÌôî???¨ÏÉù?Ä OS Í∂åÌïúÍ≥??àÏ†Ñ???Ä?•ÏÜå ?∞Îèô ???úÍ≥µ?©Îãà??',
      'familyProfilesStub':
          '?∑ÌîåÎ¶?ä§Ï≤òÎüº ?ÑÎ°ú?ÑÏùÑ Î∞îÍøâ?àÎã§. ?úÎ≤Ñ ?ôÍ∏∞?îÎäî ?¥ÌõÑ ?∞Í≤∞?????àÏäµ?àÎã§.',
      'pushStub':
          'Firebase Cloud Messaging(?êÎäî ?ôÎì±) ?§Ï†ï ???¨Í∏∞??Ï±ÑÎÑê¬∑?†Í???Ïº?ãà??',
      'homeLayoutHint': 'Î©îÏù∏ ?îÎ©¥??Î≥¥Ïùº Î∏îÎ°ù???†ÌÉù?òÏÑ∏??',
      'searchStub': '?Ω¬∑ÏΩò?êÏ∏† Í≤Ä?????∞Ïù¥???åÏä§?Ä ?∞Í≤∞ ?àÏ†ï.',
      'moreStub': '?§Ï†ï¬∑?ΩÍ? ?????ÑÏöî ???ïÏû•.',
      'save': '?Ä??,
      'activeProfile': '?ÑÏû¨ ?ÑÎ°ú??,
      'addProfile': '?ÑÎ°ú??Ï∂îÍ?',
      'reload': '???§Ïãú Î∂àÎü¨?§Í∏∞',
      'language': '?∏Ïñ¥',
      'languageSystem': '?úÏä§???∞Î¶Ñ',
      'languageEnglish': '?ÅÏñ¥',
      'languageKorean': '?úÍµ≠??,
      'recordVoiceImport': '?πÏùå ?êÎäî Í∞Ä?∏Ïò§Í∏?,
      'aiChatTitle': 'AI Ï±ÑÌåÖ¬∑?∏Ïãù',
      'aiChatSubtitle': 'Ï≤òÎ∞©???ÅÏñë?úÎ? Î∂ÑÏÑù?òÍ≥† ?†Ìò∏?±ÏúºÎ°?Î≥µÏö© ?àÏ†Ñ?ÑÎ? ?úÏãú?©Îãà??',
      'aiSymptomInputLabel': 'Ï¶ùÏÉÅ???ÖÎ†•?òÏÑ∏??,
      'aiPrimaryAnswerButton': 'Î™ÖÌôï??1Ï∞??µÎ? Î∞õÍ∏∞',
      'aiOcrInputLabel': '?¥Î?ÏßÄ ?∏Ïãù(OCR) ?çÏä§??,
      'aiOcrInputHint': 'Ï≤òÎ∞©???ÅÏñë???ºÎ≤® OCR Í≤∞Í≥ºÎ•?Î∂ôÏó¨?£Ïúº?∏Ïöî',
      'aiAnalyzeImageButton': '?¥Î?ÏßÄ ?çÏä§??Î∂ÑÏÑù',
    },
  };

  String _t(String key) {
    final lang = locale.languageCode;
    final table = _m[lang] ?? _m['en']!;
    return table[key] ?? _m['en']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get homeTitle => _t('homeTitle');
  String get familyVoiceTitle => _t('familyVoiceTitle');
  String get familyVoiceSubtitle => _t('familyVoiceSubtitle');
  String get familyProfilesTitle => _t('familyProfilesTitle');
  String get familyProfilesSubtitle => _t('familyProfilesSubtitle');
  String get pushSettingsTitle => _t('pushSettingsTitle');
  String get pushSettingsSubtitle => _t('pushSettingsSubtitle');
  String get homeLayoutTitle => _t('homeLayoutTitle');
  String get homeLayoutSubtitle => _t('homeLayoutSubtitle');
  String get medicineGuideTitle => _t('medicineGuideTitle');
  String get medicineGuideSubtitle => _t('medicineGuideSubtitle');
  String get searchTitle => _t('searchTitle');
  String get moreTitle => _t('moreTitle');
  String get login => _t('login');
  String get signup => _t('signup');
  String get medicineGuideIntro => _t('medicineGuideIntro');
  String get medicineGuideMaxDoses => _t('medicineGuideMaxDoses');
  String get familyVoiceStub => _t('familyVoiceStub');
  String get familyProfilesStub => _t('familyProfilesStub');
  String get pushStub => _t('pushStub');
  String get homeLayoutHint => _t('homeLayoutHint');
  String get searchStub => _t('searchStub');
  String get moreStub => _t('moreStub');
  String get save => _t('save');
  String get activeProfile => _t('activeProfile');
  String get addProfile => _t('addProfile');
  String get reload => _t('reload');
  String get language => _t('language');
  String get languageSystem => _t('languageSystem');
  String get languageEnglish => _t('languageEnglish');
  String get languageKorean => _t('languageKorean');
  String get recordVoiceImport => _t('recordVoiceImport');
  String get aiChatTitle => _t('aiChatTitle');
  String get aiChatSubtitle => _t('aiChatSubtitle');
  String get aiSymptomInputLabel => _t('aiSymptomInputLabel');
  String get aiPrimaryAnswerButton => _t('aiPrimaryAnswerButton');
  String get aiOcrInputLabel => _t('aiOcrInputLabel');
  String get aiOcrInputHint => _t('aiOcrInputHint');
  String get aiAnalyzeImageButton => _t('aiAnalyzeImageButton');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
