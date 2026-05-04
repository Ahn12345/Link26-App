import 'package:link26_app/shared/enums/safety_signal.dart';

export 'package:link26_app/shared/enums/safety_signal.dart';

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
