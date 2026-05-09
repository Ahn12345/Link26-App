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
  String get loginFailed => '이메일 또는 비밀번호가 일치하지 않습니다.';

  @override
  String get signupEmailTaken => '이미 가입된 이메일입니다.';

  @override
  String get signupNameLabel => '표시 이름 (선택)';

  @override
  String get socialLoginComingSoon => '소셜 로그인은 여기에 연결됩니다.';

  @override
  String get socialLoginGoogle => 'Google로 계속';

  @override
  String get socialLoginApple => 'Apple로 계속';
}
