import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';

class RecentChatResultCard extends StatelessWidget {
  const RecentChatResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(l10n.aiChatTitle),
        subtitle: Text(l10n.searchStub),
      ),
    );
  }
}
