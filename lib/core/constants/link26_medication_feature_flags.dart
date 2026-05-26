/// 복약 목록 기능 스위치 (임시 운영용).
///
/// [tilkoHiraRemoteSyncEnabled] 가 false 이면 틸코·BFF 심평원/건보 API는 호출하지 않고
/// 처방전 촬영·직접 등록만 사용합니다. 다시 켤 때는 true 로 바꾼 뒤 앱 재빌드.
abstract final class Link26MedicationFeatureFlags {
  static const bool tilkoHiraRemoteSyncEnabled = false;
}
