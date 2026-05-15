import 'app_localizations.dart';

class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo() : super('ko');

  @override
  String get appTitle => '링크26 앱';

  @override
  String get homeTitle => '홈';

  @override
  String get familyVoiceTitle => '가족 목소리 알림';

  @override
  String get familyVoiceSubtitle => '전화 알림처럼 들리는 가족 음성 등록';

  @override
  String get familyProfilesTitle => '가족 계정';

  @override
  String get familyProfilesSubtitle => '넷플릭스처럼 프로필 전환';

  @override
  String get pushSettingsTitle => '푸시 알림';

  @override
  String get pushSettingsSubtitle => '일반 알림·채널 설정';

  @override
  String get homeLayoutTitle => '메인 화면 구성';

  @override
  String get homeLayoutSubtitle => '메인에 보일 정보 선택';

  @override
  String get medicineGuideTitle => '약 복용 안내';

  @override
  String get medicineGuideSubtitle => '약 종류별 방법·횟수·04시 기준 초기화';

  @override
  String get searchTitle => '검색';

  @override
  String get moreTitle => '더보기';

  @override
  String get login => '로그인';

  @override
  String get signup => '회원가입';

  @override
  String get authWelcomeSubtitle => '로그인 또는 회원가입 후 홈 화면으로 이동합니다.';

  @override
  String get authSocialLoginComingSoon =>
      '소셜 로그인은 준비 중입니다. 휴대폰 번호 로그인을 이용해 주세요.';

  @override
  String get authKakaoLogin => '카카오 로그인';

  @override
  String get authGoogleLogin => 'Google 로그인';

  @override
  String get continueCta => '계속';

  @override
  String get loginEmailLabel => '이메일';

  @override
  String get loginPasswordLabel => '비밀번호';

  @override
  String get loginFieldsRequired => '이메일과 비밀번호를 입력하세요.';

  @override
  String get signOut => '로그아웃';

  @override
  String get homeLandingHint => '하단 탭: 홈 · AI 채팅 · 설정';

  @override
  String get moreMenuSectionTitle => '기능';

  @override
  String get medicineGuideIntro =>
      '약 종류별로 복용 주기·방법을 안내합니다. 복용 횟수 집계와 AI 맥락은 매일 04:00(로컬)에 초기화되는 하루 기준을 씁니다.';

  @override
  String get medicineGuideMaxDoses =>
      '하루 창에서 최대 10회까지 모델에 담을 수 있습니다(처방에 맞게 추후 조정).';

  @override
  String get familyVoiceStub =>
      '가족 음성 녹음·전화형 재생은 OS 권한과 안전한 저장소 연동 후 제공됩니다.';

  @override
  String get familyProfilesStub =>
      '넷플릭스처럼 프로필을 바꿉니다. 서버 동기화는 이후 연결할 수 있습니다.';

  @override
  String get pushStub =>
      'Firebase Cloud Messaging(또는 동등) 설정 후 여기서 채널·토글을 켭니다.';

  @override
  String get homeLayoutHint => '메인 화면에 보일 블록을 선택하세요.';

  @override
  String get searchStub => '약·콘텐츠 검색 — 데이터 소스와 연결 예정.';

  @override
  String get moreStub => '설정·약관 등 — 필요 시 확장.';

  @override
  String get save => '저장';

  @override
  String get reload => '홈 다시 불러오기';

  @override
  String get activeProfile => '현재 프로필';

  @override
  String get addProfile => '프로필 추가';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 따름';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageKorean => '한국어';

  @override
  String get recordVoiceImport => '녹음 또는 가져오기';

  @override
  String get aiChatTitle => 'AI 채팅';

  @override
  String get aiChatSubtitle =>
      '처방전/영양제를 분석하고 신호등으로 복용 안전도를 표시합니다.';

  @override
  String get aiSymptomInputLabel => '증상을 입력하세요';

  @override
  String get aiPrimaryAnswerButton => '명확한 1차 답변 받기';

  @override
  String get aiOcrInputLabel => '이미지 인식(OCR) 텍스트';

  @override
  String get aiOcrInputHint => '처방전/영양제 라벨 OCR 결과를 붙여넣으세요';

  @override
  String get aiAnalyzeImageButton => '이미지 텍스트 분석';

  @override
  String get aiChatBrandTitle => 'AI 약 정보';

  @override
  String get aiChatQuotaResetHint => '오전 4시에 초기화됩니다';

  @override
  String get aiChatInputPlaceholder => '약에 대해 궁금한 점을 물어보세요…';

  @override
  String get aiChatDailyLimitReached =>
      '오늘 AI 질문 한도에 도달했습니다. 매일 오전 4시(로컬)에 다시 이용할 수 있습니다.';

  @override
  String get aiChatResetQuotaButton => '이 기기에서 한도 초기화';

  @override
  String get aiChatResetQuotaTitle => '이 기기 한도 초기화';

  @override
  String get aiChatResetQuotaMessage =>
      '이 기기에 저장된 오늘 사용 횟수만 0으로 돌아갑니다. 대화 내용은 그대로이며, 다른 기기나 서버 정책과는 별개입니다.';

  @override
  String get aiChatResetQuotaConfirm => '초기화';

  @override
  String get aiChatResetQuotaCancel => '취소';

  @override
  String get aiChatResetQuotaDone => '이 기기 한도를 초기화했습니다.';

  @override
  String get aiChatAttachGalleryTooltip => '갤러리에서 이미지 선택';

  @override
  String get aiChatReplyError =>
      '일시적으로 응답을 가져오지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get aiChatGeminiKeyMissing =>
      'Gemini API 키가 없습니다. Google AI Studio(https://aistudio.google.com/apikey)에서 발급 후 루트 `.env`에 GEMINI_API_KEY=... 를 넣고, `tool/sync_dotenv_asset.ps1`(또는 run_bff_and_flutter.ps1)로 assets/env/dotenv를 갱신한 뒤 앱을 다시 빌드하세요.';

  @override
  String get aiChatDisclaimerShort =>
      'AI가 제공하는 정보는 참고용입니다. 정확한 복용 방법은 의사나 약사와 상담하세요.';

  @override
  String get aiChatCameraUserMessage => '사진을 선택했습니다.';

  @override
  String get aiChatCameraReplyStub =>
      '이미지 분석은 image_picker·업로드 API 연결 후 표시됩니다.';

  @override
  String get aiChatPickCamera => '카메라로 촬영';

  @override
  String get aiChatPickGallery => '갤러리에서 선택';

  @override
  String get aiChatImageUserCaption => '[처방전·약 사진 보냄]';

  @override
  String get aiChatImageAnalyzing => '이미지를 분석하는 중…';

  @override
  String get aiChatImageOpenFailed =>
      '카메라·사진 앱을 열 수 없습니다. 권한을 허용했는지 확인하세요.';

  @override
  String get aiChatImageReadFailed => '이미지 파일을 읽지 못했습니다.';

  @override
  String get aiChatImagePendingHint => '사진 첨부됨 · 내용 입력 후 전송';

  @override
  String get aiChatImagePendingSnack =>
      '질문이나 설명을 입력한 뒤 전송 버튼을 눌러 주세요.';

  @override
  String get aiChatImageNeedText =>
      '이미지와 함께 보내려면 질문이나 설명을 먼저 입력해 주세요.';

  @override
  String get aiChatWelcomeIntro => '안녕하세요! 약 정보를 도와드리겠습니다.\n\n';

  @override
  String get aiChatWelcomeUploadHint =>
      '처방전이나 약 사진을 업로드하시면 약 정보를 확인해드립니다.\n\n';

  @override
  String get aiChatWelcomeTipEmoji => '💡 ';

  @override
  String get aiChatWelcomeTipTitle => '사진 촬영 팁:';

  @override
  String get aiChatWelcomeTipList =>
      '- 약 이름과 용량이 선명하게 보이도록 촬영해 주세요\n'
      '- 처방전의 경우 약 이름 부분이 잘 보이게 촬영해 주세요\n'
      '- 밝은 곳에서 촬영하시면 더 정확합니다';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '글자 크기·접근성';

  @override
  String get settingsTextSize => '글자 크기';

  @override
  String get medicineCatalogTitle => '약 목록';

  @override
  String get medicineCatalogSubtitle =>
      '등록된 항목(데모). 이후 서버·로컬 DB와 연결하세요.';

  @override
  String get medicineCatalogTooltip => '약 목록 열기';

  @override
  String get medicineCatalogEmpty => '표시할 약이 없습니다.';

  @override
  String get homeTodayAlertsTitle => '오늘의 알림';

  @override
  String get homeAiChatImageReplyTitle => 'AI 약 정보 답변 도착';

  @override
  String get homeAiChatImageReplyCta => 'AI 채팅에서 보기';

  @override
  String get homeNotificationCenterTitle => '알림';

  @override
  String get homeNotificationMarkAiRead => 'AI 읽음';

  @override
  String get homeNotificationTabAll => '전체';

  @override
  String get homeNotificationTabAi => 'AI';

  @override
  String get homeNotificationTabDose => '복용';

  @override
  String get homeNotificationTabCall => '전화';

  @override
  String get homeNotificationSectionAi => 'AI 약 정보';

  @override
  String get homeNotificationSectionDose => '복용 알림';

  @override
  String get homeNotificationSectionCall => '전화 복용 안내';

  @override
  String get homeNotificationEmptyAi => 'AI 분석 알림이 없습니다.';

  @override
  String get homeNotificationEmptyDose => '앱 복용 알림이 없습니다.';

  @override
  String get homeNotificationEmptyCall => '전화 복용 알림이 없습니다.';

  @override
  String get homeNotificationNewBadge => 'NEW';

  @override
  String get homeNotificationKindApp => '알림';

  @override
  String get homeNotificationKindCall => '전화';

  @override
  String get homeNotificationDoseConfirmed => '확인됨';

  @override
  String get homeNotificationMarkDoseDone => '복용 완료';

  @override
  String get homeNotificationSectionSystem => '시스템 알림';

  @override
  String get homeNotificationSectionOther => '기타 · 공지';

  @override
  String get homeNotificationEmptySystem => '시스템 연동 알림이 없습니다.';

  @override
  String get homeNotificationMarkSystemRead => '시스템 읽음';

  @override
  String get homeNotificationSystemSyncTitle => '복약·연동';

  @override
  String get homeNoticeOtherTitle => '서비스 공지';

  @override
  String get homeNoticeOtherBody =>
      '건강 보조 식품 추천·이벤트 등 안내는 이 섹션에 모읍니다. 홈 하단 배너 대신 여기서 확인하세요.';

  @override
  String get authErrorTitle => '연결 오류';

  @override
  String get authErrorBody =>
      '일시적으로 처리할 수 없습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.';

  @override
  String get authErrorBack => '돌아가기';

  @override
  String get homeTodayAlertsViewAll => '전체 보기';

  @override
  String get homeMyMedicinesTitle => '내 약 목록';

  @override
  String get homeAddMedicine => '추가';

  @override
  String get homeNoMedicinesYet =>
      '등록된 약이 없습니다. 추가로 검색해 등록하세요.';

  @override
  String get alertsScreenTitle => '오늘의 알림';

  @override
  String get alertItemWater => '물 마시기';

  @override
  String get alertItemVitamin => '영양제';

  @override
  String get alertItemWalk => '가벼운 산책';

  @override
  String get pillSearchTitle => '약 검색';

  @override
  String get pillSearchLabel => '약 이름';

  @override
  String get pillSearchHint => '목록에 넣을 약 이름을 입력';

  @override
  String get pillSearchAdded => '목록에 추가했습니다.';

  @override
  String get settingsEmergencyContact => '긴급 연락처';

  @override
  String get settingsEmergencyContactSubtitle => '전화형 알림·연락';

  @override
  String get settingsFamilyAddEntry => '가족 구성원 추가';

  @override
  String get settingsCodefConnectionTitle => '복약 추가 설정 (선택)';

  @override
  String get settingsCodefConnectionSubtitle =>
      '심평원 복약은 틸코 간편인증(BFF)으로 불러옵니다. 아래 connectedId는 BFF에서 예전 CODEF GET 복약만 쓸 때 필요합니다.';

  @override
  String get settingsCodefConnectedIdLabel => 'connectedId (선택)';

  @override
  String get settingsCodefConnectionHint =>
      'CODEF 기관 연동을 쓰는 경우에만 콘솔·API에서 발급된 값';

  @override
  String get settingsCodefConnectionSaved =>
      '저장했습니다. 홈에서 복약 동기화를 다시 실행해 보세요.';

  @override
  String get settingsCodefConnectionPhoneRequired =>
      '로그인된 전화번호가 없습니다. 먼저 로그인해 주세요.';

  @override
  String get settingsCodefConnectionClear => '지우기';

  @override
  String get emergencyContactStub =>
      '긴급 연락처와 통화 바로가기를 등록합니다. (데모 — 이후 tel: 및 권한 연동)';

  @override
  String get emergencyCallPlaceholder => '다이얼 연동 예정입니다.';

  @override
  String get emergencyCallAction => '긴급 연락처에 전화';

  @override
  String get monthlyHiraTitle => '매월 간편인증 (25일)';

  @override
  String get monthlyHiraBody =>
      '심사평가원·공단 데이터 갱신을 위해 매달 1회 간편인증이 필요합니다. 1/2 단계입니다.';

  @override
  String get monthlyHiraPrimaryAction => '간편인증';

  @override
  String get monthlyHiraSecondTitle => '인증 확인';

  @override
  String get monthlyHiraSecondHint =>
      '2단계: 기관 간편인증 흐름을 완료합니다(데모).';

  @override
  String get monthlyHiraComplete => '완료';

  @override
  String get later => '나중에';

  @override
  String get loginFailed =>
      '이름과 전화번호가 저장된 정보와 일치하지 않습니다.';

  @override
  String get loginRedirectToSignup =>
      '등록된 회원 정보가 없습니다. 회원가입을 진행해 주세요.';

  @override
  String get loginNameMismatch =>
      '이름이 가입 시 입력한 정보와 일치하지 않습니다.';

  @override
  String get loginNameLabel => '이름';

  @override
  String get loginNameRequired => '이름을 입력하세요.';

  @override
  String get loginNhisSyncFailed =>
      '국민건강보험(연동 서버) 로그인 연동에 실패했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get loginNhisRequiredFailed =>
      '국민건강보험 연동이 완료되지 않아 로그인할 수 없습니다. 네트워크·API 설정을 확인해 주세요.';

  @override
  String get signupEmailTaken => '이미 가입된 이메일입니다.';

  @override
  String get signupPhoneTaken => '이미 가입된 전화번호입니다.';

  @override
  String get signupNhisSyncFailed =>
      '국민건강보험(연동 서버) 전송에 실패했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get signupNhisRequiredFailed =>
      '국민건강보험 연동이 완료되지 않아 가입할 수 없습니다. 네트워크·API 설정을 확인해 주세요.';

  @override
  String get loginPhoneRequired => '전화번호를 입력하세요.';

  @override
  String get signupNameLabel => '이름';

  @override
  String get signupPhoneLabel => '전화번호';

  @override
  String get signupPhoneInvalid => '전화번호를 올바르게 입력하세요. (숫자 10~11자리)';

  @override
  String get signupGenderLabel => '성별';

  @override
  String get signupGenderMale => '남자';

  @override
  String get signupGenderFemale => '여자';

  @override
  String get signupGenderRequired => '성별을 선택하세요.';

  @override
  String get signupBirthLabel => '생년월일';

  @override
  String get signupBirthHint => 'YYYYMMDD (예: 20040522)';

  @override
  String get signupBirthInvalid => '생년월일 8자리(YYYYMMDD)를 올바르게 입력하세요.';

  @override
  String get signupBirthRrnMismatch =>
      '생년월일과 주민등록번호 앞자리가 맞지 않습니다.';

  @override
  String get signupBirthRequired => '생년월일을 입력하세요.';

  @override
  String get signupRrnLabel => '주민등록번호';

  @override
  String get signupRrnHint => '하이픈 없이 숫자 13자리';

  @override
  String get signupRrnInvalid => '주민등록번호 13자리를 입력하세요.';

  @override
  String get signupPrivacyAgree => '(필수) 개인정보 수집·이용에 동의합니다.';

  @override
  String get signupPrivacyRequired => '개인정보 동의는 필수입니다.';

  @override
  String get signupPrivacyDetailLink => '[상세정보]';

  @override
  String get privacyConsentDocumentTitle => '개인정보 수집·이용 동의서';

  @override
  String get privacyConsentOpenFailed =>
      '동의서 PDF를 불러오지 못했습니다. 앱을 다시 시작한 뒤 다시 시도해 주세요.';

  @override
  String get guidePrivacyConsentSubtitle => '앱에 포함된 전문(PDF)';

  @override
  String get moreMenuLanguageSubtitle => '기본: 한국어 · English';

  @override
  String get signupNameRequired => '이름을 입력하세요.';

  @override
  String get signupRequiredIncomplete => '필수 항목을 모두 입력·동의해 주세요.';

  @override
  String get socialLoginComingSoon => '소셜 로그인은 여기에 연결됩니다.';

  @override
  String get socialLoginGoogle => 'Google로 계속';

  @override
  String get socialLoginApple => 'Apple로 계속';

  @override
  String get loginDividerEmail => '또는 전화번호로 로그인';

  @override
  String get loginDividerLocalAccount => '이름과 전화번호로 로그인';

  @override
  String get authContinueLoginHint =>
      '이름과 휴대전화 번호(숫자 10~11자리)를 입력하면 계속 버튼이 활성화됩니다.';

  @override
  String get authContinueSignupHint =>
      '이름·전화·성별·주민등록번호 13자리·(필수) 개인정보 동의를 모두 입력하면 계속 버튼이 활성화됩니다.';

  @override
  String get authSessionInitFailed =>
      '로컬 계정 정보를 불러오지 못했습니다. 앱을 다시 시작하거나 저장 공간을 확인해 주세요.';

  @override
  String get signupSubmitFailed =>
      '회원가입 처리 중 오류가 발생했습니다. 입력 내용을 확인하거나 앱을 다시 시작해 주세요.';

  @override
  String get healthLinkTitle => '심평원 복약 연동 (틸코)';

  @override
  String get healthLinkSubtitle =>
      'BFF(NHIS_BASE_URL)에 TILKO_API_KEY를 두면 틸코 간편인증 후 심평원 「내가 먹는 약」조회를 서버에서 처리합니다. '
      'BFF가 없을 때만 앱 .env의 TILKO_API_KEY로 간편인증만 직접 호출할 수 있습니다(개발용).';

  @override
  String get healthLinkFlowCta => '간편인증 후 복약 조회';

  @override
  String get healthLinkTilkoOnlyCta => '틸코 간편인증만';

  @override
  String get healthLinkBffHint =>
      'NHIS_BASE_URL이 있으면 틸코·e약은요 등은 BFF로 요청합니다. '
      'NHIS_USE_MOCK은 가입·로그인·복약 동기화 목에만 해당합니다.';

  @override
  String get healthLinkDirectHint =>
      'BFF를 쓰지 않을 때는 TILKO_API_KEY가 있어야 합니다.';

  @override
  String get healthLinkJsonLabel => 'BFF 추가 JSON(객체 · 선택)';

  @override
  String get pillSearchPublicDataTitle => '공공데이터 e약은요 (BFF)';

  @override
  String get pillSearchPublicDataEmpty =>
      'BFF 연결 시 약 이름으로 식약처 요약을 불러옵니다.';

  @override
  String get pillSearchNeedBffUrl =>
      '.env에 NHIS_BASE_URL을 BFF 주소로 넣고(예: 에뮬 http://10.0.2.2:8787), sync 후 BFF 실행·앱 재빌드하세요.';

  @override
  String get tilkoNhisLinkTitle => '심평원 복약 불러오기';

  @override
  String get tilkoNhisLinkBody =>
      '틸코 간편인증 후 건강보험심사평가원 「내가 먹는 약」처방·투약 이력을 불러옵니다. 주민등록번호 13자리는 기기에 저장되지 않으며, 이번 조회에만 사용됩니다.';

  @override
  String get tilkoNhisLinkRrnLabel => '주민등록번호(숫자 13자리)';

  @override
  String get tilkoNhisLinkConfirm => '인증 후 조회';

  @override
  String get tilkoNhisLinkSkip => '나중에';

  @override
  String get tilkoNhisLinkRrnInvalid =>
      '주민등록번호 13자리를 올바르게 입력해 주세요.';

  @override
  String get homeHiraMedicationsImport => '심평원에서 불러오기';

  @override
  String get homeHiraMedicationsBffRequired =>
      'PC BFF가 실행 중이고 앱에 NHIS_BASE_URL(BFF 주소)이 있어야 합니다.';

  @override
  String get homeHiraMedicationsLoginRequired => '로그인된 계정이 필요합니다.';

  @override
  String get homeHiraMedicationsLoadSuccess => '심평원 복약을 내 약 목록에 반영했습니다.';

  @override
  String get myMedicinesFullViewCta => '전체보기';

  @override
  String get myMedicinesPeriod1m => '1개월';

  @override
  String get myMedicinesPeriod3m => '3개월';

  @override
  String get myMedicinesPeriod6m => '6개월';

  @override
  String get myMedicinesPeriod1y => '1년';

  @override
  String get myMedicinesPeriodLabel => '조회 기간:';

  @override
  String get myMedicinesPeriodHint =>
      '복약 목록은 동기화 시점의 전체입니다. 아래 기간 칩은 「복용 완료」 기록만 해당 기간으로 집계합니다.';

  @override
  String get myMedicinesSyncedSectionTitle => '동기화된 약';

  @override
  String get myMedicinesCompletionsSectionTitle => '기간 내 복용 완료';

  @override
  String get myMedicinesNoMedicines =>
      '동기화된 약이 없습니다. 홈에서 「심평원에서 불러오기」를 이용하거나 약을 추가해 보세요.';

  @override
  String get myMedicinesNoCompletions =>
      '이 기간에 복용 완료 기록이 없습니다.';

  @override
  String get myMedicinesAddMedicineFab => '약 추가';

  @override
  @override
  String myMedicinesCompletionCountLabel(int count) => '$count회';
}
