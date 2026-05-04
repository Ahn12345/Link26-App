import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';

class MedicineOverviewCard extends StatelessWidget {
  const MedicineOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: ListTile(
        leading: const Icon(Icons.medication),
        title: Text(l10n.medicineGuideTitle),
        subtitle: Text(l10n.medicineGuideSubtitle),
      ),
    );
  }
}
