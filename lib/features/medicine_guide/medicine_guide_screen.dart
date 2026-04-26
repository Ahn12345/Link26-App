import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import '../../core/domain/daily_window_policy.dart';

class MedicineGuideScreen extends StatelessWidget {
  const MedicineGuideScreen({super.key});

  static const routeName = '/medicine-guide';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const policy = DailyWindowPolicy();
    final now = DateTime.now();
    final start = policy.windowStartFor(now);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.medicineGuideTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.medicineGuideSubtitle),
          const SizedBox(height: 12),
          Text(l10n.medicineGuideIntro),
          const SizedBox(height: 12),
          Text(l10n.medicineGuideMaxDoses),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current window (demo)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Now: $now'),
                  Text('Window start (04:00 rule): $start'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Example types (placeholder)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.medication_liquid),
            title: Text('Liquid — with food, 3× daily'),
            subtitle: Text('Max 10 logs / window in model'),
          ),
          const ListTile(
            leading: Icon(Icons.medication),
            title: Text('Tablet — empty stomach, morning'),
            subtitle: Text('Link to DUR data later'),
          ),
        ],
      ),
    );
  }
}
