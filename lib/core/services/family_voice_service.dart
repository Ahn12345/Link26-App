/// ê°€ì¡??Œì„± ?´ë¦½ ë©”í?(?¤ì œ ?¹ìŒ/?¬ìƒ?€ ?¤ì´?°ë¸ŒÂ·ê¶Œí•œÂ·?€?¥ì†Œ ?°ë™ ??êµ¬í˜„).
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
    // TODO: ?¹ìŒ/?Œì¼ ?¼ì»¤ ?????€?¥ì†Œ ë³µì‚¬, ë©”í? DB ?€??
  }
}
