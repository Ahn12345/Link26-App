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
  String get aiChatTitle => 'AI 채팅·인식';

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
}
