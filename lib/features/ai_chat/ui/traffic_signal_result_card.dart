import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../ai_chat_models.dart';

class TrafficSignalResultCard extends StatelessWidget {
  const TrafficSignalResultCard({super.key, required this.insight});

  final MedicineInsight insight;

  Color _color(BuildContext context) {
    switch (insight.signal) {
      case SafetySignal.green:
        return Colors.green;
      case SafetySignal.yellow:
        return Colors.orange;
      case SafetySignal.red:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        leading: Icon(Icons.circle, color: _color(context)),
        title: Text(insight.recommendation),
        subtitle: Text(insight.reason),
      ),
    );
  }
}
