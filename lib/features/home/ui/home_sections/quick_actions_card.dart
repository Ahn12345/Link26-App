import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/ai_chat_screen.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.aiChatTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AiChatScreen.routeName);
            },
            icon: const Icon(Icons.smart_toy),
            label: Text(l10n.aiPrimaryAnswerButton),
          ),
        ],
      ),
    );
  }
}
