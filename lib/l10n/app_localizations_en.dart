import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appTitle => 'Link26 App';

  @override
  String get homeTitle => 'Home';

  @override
  String get familyVoiceTitle => 'Family voice alerts';

  @override
  String get familyVoiceSubtitle =>
      'Register voices for call-style reminders';

  @override
  String get familyProfilesTitle => 'Family profiles';

  @override
  String get familyProfilesSubtitle => 'Netflix-style household accounts';

  @override
  String get pushSettingsTitle => 'Push notifications';

  @override
  String get pushSettingsSubtitle => 'General alerts & channels';

  @override
  String get homeLayoutTitle => 'Home screen layout';

  @override
  String get homeLayoutSubtitle => 'Choose what appears on the main screen';

  @override
  String get medicineGuideTitle => 'Medicine guide';

  @override
  String get medicineGuideSubtitle =>
      'How to take each medicine, daily limits, AI reset';

  @override
  String get searchTitle => 'Search';

  @override
  String get moreTitle => 'More';

  @override
  String get login => 'Log in';

  @override
  String get signup => 'Sign up';

  @override
  String get medicineGuideIntro =>
      'Each medicine type can show how often to take it. The app treats a day as starting at 04:00 local time for counters and AI context reset.';

  @override
  String get medicineGuideMaxDoses =>
      'The model allows up to 10 doses in that daily window (adjust per prescription in a future build).';

  @override
  String get familyVoiceStub =>
      'Voice recording and call-style playback will use OS permissions and secure storage.';

  @override
  String get familyProfilesStub =>
      'Switch profiles like Netflix; data can sync to a backend later.';

  @override
  String get pushStub =>
      'Enable categories here after Firebase Cloud Messaging (or equivalent) is configured.';

  @override
  String get homeLayoutHint => 'Toggle blocks shown on the home screen.';

  @override
  String get searchStub =>
      'Medicine and content search — connect to your data sources.';

  @override
  String get moreStub => 'Settings and legal links — expand as needed.';

  @override
  String get save => 'Save';

  @override
  String get reload => 'Reload home';

  @override
  String get activeProfile => 'Active profile';

  @override
  String get addProfile => 'Add profile';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => 'Korean';

  @override
  String get recordVoiceImport => 'Record / import';

  @override
  String get aiChatTitle => 'AI Chat & Recognition';

  @override
  String get aiChatSubtitle =>
      'Analyze prescriptions/supplements and show traffic-light safety.';

  @override
  String get aiSymptomInputLabel => 'Describe your symptoms';

  @override
  String get aiPrimaryAnswerButton => 'Get clear first answer';

  @override
  String get aiOcrInputLabel => 'Recognized text from image';

  @override
  String get aiOcrInputHint =>
      'Paste OCR text from prescription or supplement label';

  @override
  String get aiAnalyzeImageButton => 'Analyze image text';
}
