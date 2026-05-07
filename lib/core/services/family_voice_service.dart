/// Family voice clip metadata service stub.
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
    // TODO: Save selected audio file and metadata locally.
  }
}
