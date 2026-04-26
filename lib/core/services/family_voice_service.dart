/// 가족 음성 클립 메타(실제 녹음/재생은 네이티브·권한·저장소 연동 후 구현).
class FamilyVoiceClip {
  const FamilyVoiceClip({
    required this.id,
    required this.label,
    required this.relativePath,
  });

  final String id;
  final String label;
  final String relativePath;
}

class FamilyVoiceService {
  Future<List<FamilyVoiceClip>> listClips() async => const [];

  Future<void> registerFromFile({
    required String label,
    required String filePath,
  }) async {
    // TODO: 녹음/파일 피커 → 앱 저장소 복사, 메타 DB 저장
  }
}
