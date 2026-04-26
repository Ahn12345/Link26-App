enum SafetySignal { green, yellow, red }

class MedicineInsight {
  const MedicineInsight({
    required this.productName,
    required this.signal,
    required this.recommendation,
    required this.reason,
  });

  final String productName;
  final SafetySignal signal;
  final String recommendation;
  final String reason;
}

class ChatTriageResult {
  const ChatTriageResult({
    required this.urgent,
    required this.primaryAnswer,
    required this.followUpPrompt,
  });

  final bool urgent;
  final String primaryAnswer;
  final String followUpPrompt;
}
