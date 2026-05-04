import 'package:flutter/material.dart';

import '../ai_chat_models.dart';

class TriagePriorityBanner extends StatelessWidget {
  const TriagePriorityBanner({super.key, required this.result});

  final ChatTriageResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: result.urgent ? Colors.red.shade50 : Colors.green.shade50,
      child: ListTile(
        leading: Icon(
          result.urgent ? Icons.warning_amber : Icons.check_circle,
        ),
        title: Text(result.primaryAnswer),
        subtitle: Text(result.followUpPrompt),
      ),
    );
  }
}
