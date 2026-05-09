import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/services/home_layout_store.dart';
import '../../core/services/local_medicine_list_store.dart';
import '../search/pill_search_screen.dart';
import 'alerts_list_screen.dart';

/// 홈 탭: 오늘의 알림, 내 약 목록 + 추가(pillsearch), 기존 히어로 블록.
class HomeLandingScreen extends StatefulWidget {
  const HomeLandingScreen({super.key});

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen> {
  Set<String> _visible = {...HomeLayoutStore.allBlockIds};
  bool _loading = true;
  List<String> _medicines = [];

  static const _homeHeroAsset = 'assets/images/Home.png';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await HomeLayoutStore.loadVisible();
    final m = await LocalMedicineListStore.load();
    if (mounted) {
      setState(() {
        _visible = v;
        _medicines = m;
        _loading = false;
      });
    }
  }

  Future<void> _openPillSearch() async {
    await Navigator.of(context).pushNamed(PillSearchScreen.routeName);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Text(
                  l10n.homeTodayAlertsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: Text(l10n.homeTodayAlertsViewAll),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AlertsListScreen.routeName),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeMyMedicinesTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _openPillSearch,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(l10n.homeAddMedicine),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_medicines.isEmpty)
                  Text(
                    l10n.homeNoMedicinesYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  ..._medicines.map(
                    (name) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await LocalMedicineListStore.remove(name);
                            await _load();
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_visible.contains('logo'))
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, size: 56),
                  ),
                if (_visible.contains('logo')) const SizedBox(height: 16),
                if (_visible.contains('title'))
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                if (_visible.contains('title')) const SizedBox(height: 8),
                if (_visible.contains('subtitle'))
                  Text(
                    l10n.medicineGuideSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                if (_visible.contains('familySummary'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.familyProfilesSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _homeHeroAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('home hero: $error');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.homeLandingHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
