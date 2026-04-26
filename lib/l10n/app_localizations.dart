import 'package:flutter/material.dart';

/// ARB와 동일 키 — `flutter gen-l10n` 대신 수동 유지(OneDrive 등에서 코드생성 실패 시 대비).
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
          'Each medicine type can show how often to take it. The app treats a “day” as starting at 04:00 local time for counters and AI context reset.',
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
          'Medicine and content search — connect to your data sources.',
      'moreStub': 'Settings and legal links — expand as needed.',
      'save': 'Save',
      'activeProfile': 'Active profile',
      'addProfile': 'Add profile',
      'reload': 'Reload home',
      'language': 'Language',
      'languageSystem': 'System default',
      'languageEnglish': 'English',
      'languageKorean': 'Korean',
      'recordVoiceImport': 'Record / import',
    },
    'ko': {
      'appTitle': '링크 앱',
      'homeTitle': '홈',
      'familyVoiceTitle': '가족 목소리 알림',
      'familyVoiceSubtitle': '전화 알림처럼 들리는 가족 음성 등록',
      'familyProfilesTitle': '가족 계정',
      'familyProfilesSubtitle': '넷플릭스처럼 프로필 전환',
      'pushSettingsTitle': '푸시 알림',
      'pushSettingsSubtitle': '일반 알림·채널 설정',
      'homeLayoutTitle': '메인 화면 구성',
      'homeLayoutSubtitle': '메인에 보일 정보 선택',
      'medicineGuideTitle': '약 복용 안내',
      'medicineGuideSubtitle':
          '약 종류별 방법·횟수·04시 기준 초기화',
      'searchTitle': '검색',
      'moreTitle': '더보기',
      'login': '로그인',
      'signup': '회원가입',
      'medicineGuideIntro':
          '약 종류별로 복용 주기·방법을 안내합니다. 복용 횟수 집계와 AI 맥락은 매일 04:00(로컬)에 초기화되는 ‘하루’ 기준을 씁니다.',
      'medicineGuideMaxDoses':
          '하루 창에서 최대 10회까지 모델에 담을 수 있습니다(처방에 맞게 추후 조정).',
      'familyVoiceStub':
          '가족 음성 녹음·전화형 재생은 OS 권한과 안전한 저장소 연동 후 제공됩니다.',
      'familyProfilesStub':
          '넷플릭스처럼 프로필을 바꿉니다. 서버 동기화는 이후 연결할 수 있습니다.',
      'pushStub':
          'Firebase Cloud Messaging(또는 동등) 설정 후 여기서 채널·토글을 켭니다.',
      'homeLayoutHint': '메인 화면에 보일 블록을 선택하세요.',
      'searchStub': '약·콘텐츠 검색 — 데이터 소스와 연결 예정.',
      'moreStub': '설정·약관 등 — 필요 시 확장.',
      'save': '저장',
      'activeProfile': '현재 프로필',
      'addProfile': '프로필 추가',
      'reload': '홈 다시 불러오기',
      'language': '언어',
      'languageSystem': '시스템 따름',
      'languageEnglish': '영어',
      'languageKorean': '한국어',
      'recordVoiceImport': '녹음 또는 가져오기',
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
