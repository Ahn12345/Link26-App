import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';

class InsuranceSummaryCard extends StatelessWidget {
  const InsuranceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: ListTile(
        leading: const Icon(Icons.health_and_safety),
        title: Text(l10n.familyProfilesTitle),
        subtitle: Text(l10n.familyProfilesStub),
      ),
    );
  }
}
