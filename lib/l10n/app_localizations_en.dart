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
  String get authWelcomeSubtitle =>
      'Log in or create an account to open your home screen.';

  @override
  String get continueCta => 'Continue';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginFieldsRequired =>
      'Enter email and password to continue.';

  @override
  String get signOut => 'Log out';

  @override
  String get homeLandingHint =>
      'Bottom tabs: Home, AI Chat, and Settings.';

  @override
  String get moreMenuSectionTitle => 'Features';

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
  String get aiChatTitle => 'AI Chat';

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

  @override
  String get aiChatBrandTitle => 'AI medicine info';

  @override
  String get aiChatQuotaResetHint => 'Resets at 4:00 a.m.';

  @override
  String get aiChatInputPlaceholder => 'Ask about your medicine…';

  @override
  String get aiChatDailyLimitReached =>
      'Daily AI question limit reached. It resets at 4:00 a.m. local time.';

  @override
  String get aiChatReplyError =>
      'Could not get a response. Please try again shortly.';

  @override
  String get aiChatDisclaimerShort =>
      'AI answers are for reference only. For dosing, ask your clinician or pharmacist.';

  @override
  String get aiChatCameraUserMessage => 'Photo selected.';

  @override
  String get aiChatCameraReplyStub =>
      'Image analysis will appear after wiring image_picker and upload API.';

  @override
  String get aiChatWelcomeIntro => 'Hello! I can help with medicine information.\n\n';

  @override
  String get aiChatWelcomeUploadHint =>
      'Upload a prescription or medicine photo and we will help you check the details.\n\n';

  @override
  String get aiChatWelcomeTipEmoji => '💡 ';

  @override
  String get aiChatWelcomeTipTitle => 'Photo tips:';

  @override
  String get aiChatWelcomeTipList =>
      '- Capture the name and dose clearly\n'
      '- For prescriptions, keep drug names readable\n'
      '- Good lighting improves accuracy';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Text size and accessibility';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get medicineCatalogTitle => 'Medicine list';

  @override
  String get medicineCatalogSubtitle =>
      'Known items (demo). Replace with your backend or local DB.';

  @override
  String get medicineCatalogTooltip => 'Open medicine list';

  @override
  String get medicineCatalogEmpty => 'No medicines to show.';

  @override
  String get homeTodayAlertsTitle => 'Today\'s reminders';

  @override
  String get homeTodayAlertsViewAll => 'View all reminders';

  @override
  String get homeMyMedicinesTitle => 'My medicines';

  @override
  String get homeAddMedicine => 'Add';

  @override
  String get homeNoMedicinesYet =>
      'No medicines yet. Tap Add to search and register.';

  @override
  String get alertsScreenTitle => 'Today\'s reminders';

  @override
  String get alertItemWater => 'Drink water';

  @override
  String get alertItemVitamin => 'Vitamins';

  @override
  String get alertItemWalk => 'Light walk';

  @override
  String get pillSearchTitle => 'Medicine search';

  @override
  String get pillSearchLabel => 'Medicine name';

  @override
  String get pillSearchHint => 'Enter name to add to your list';

  @override
  String get pillSearchAdded => 'Added to your list.';

  @override
  String get settingsEmergencyContact => 'Emergency contact';

  @override
  String get settingsEmergencyContactSubtitle =>
      'Call-style alerts and contacts';

  @override
  String get settingsFamilyAddEntry => 'Add family member';

  @override
  String get emergencyContactStub =>
      'Register an emergency contact and call shortcuts. (Demo — wire tel: and permissions later.)';

  @override
  String get emergencyCallPlaceholder => 'Dialer integration coming soon.';

  @override
  String get emergencyCallAction => 'Call emergency contact';

  @override
  String get monthlyHiraTitle => 'Monthly easy authentication (25th)';

  @override
  String get monthlyHiraBody =>
      'For HIRA/NHI data refresh, complete easy auth once per month. Step 1 of 2.';

  @override
  String get monthlyHiraPrimaryAction => 'Easy auth';

  @override
  String get monthlyHiraSecondTitle => 'Confirm authentication';

  @override
  String get monthlyHiraSecondHint =>
      'Step 2: confirm with your institution\'s easy-auth flow (demo).';

  @override
  String get monthlyHiraComplete => 'Done';

  @override
  String get later => 'Later';

  @override
  String get loginFailed => 'Name and phone do not match our records.';

  @override
  String get loginNameLabel => 'Name';

  @override
  String get loginNameRequired => 'Please enter your name.';

  @override
  String get loginNhisSyncFailed =>
      'NHIS login sync failed. You can try again later.';

  @override
  String get loginNhisRequiredFailed =>
      'NHIS login is required but failed. Check API settings.';

  @override
  String get signupEmailTaken => 'This email is already registered.';

  @override
  String get signupPhoneTaken => 'This phone number is already registered.';

  @override
  String get signupNhisSyncFailed =>
      'NHIS sync failed. You can try again later.';

  @override
  String get signupNhisRequiredFailed =>
      'NHIS registration is required but failed. Check API settings.';

  @override
  String get loginPhoneRequired => 'Please enter your phone number.';

  @override
  String get signupNameLabel => 'Full name';

  @override
  String get signupPhoneLabel => 'Phone number';

  @override
  String get signupPhoneInvalid =>
      'Enter a valid phone number (10–11 digits).';

  @override
  String get signupGenderLabel => 'Gender';

  @override
  String get signupGenderMale => 'Male';

  @override
  String get signupGenderFemale => 'Female';

  @override
  String get signupGenderRequired => 'Please select a gender.';

  @override
  String get signupRrnLabel => 'Resident ID (KR, 13 digits)';

  @override
  String get signupRrnHint => '13 digits, no hyphen';

  @override
  String get signupRrnInvalid => 'Enter exactly 13 digits.';

  @override
  String get signupPrivacyAgree =>
      '(Required) I agree to the collection and use of personal data.';

  @override
  String get signupPrivacyRequired => 'You must agree to personal data processing.';

  @override
  String get signupNameRequired => 'Please enter your name.';

  @override
  String get signupRequiredIncomplete =>
      'Please complete and agree to all required fields.';

  @override
  String get socialLoginComingSoon =>
      'Social sign-in will connect here.';

  @override
  String get socialLoginGoogle => 'Continue with Google';

  @override
  String get socialLoginApple => 'Continue with Apple';

  @override
  String get loginDividerEmail => 'Or continue with phone';

  @override
  String get loginDividerLocalAccount => 'Sign in with name and phone';
}
