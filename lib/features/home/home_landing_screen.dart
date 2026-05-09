import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/services/home_layout_store.dart';

/// 하단 탭 중 「홈」 — 랜딩(로고·히어로·짧은 안내)만 표시합니다.
class HomeLandingScreen extends StatefulWidget {
  const HomeLandingScreen({super.key});

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen> {
  Set<String> _visible = {...HomeLayoutStore.allBlockIds};
  bool _loading = true;

  static const _homeHeroAsset = 'assets/images/Home.png';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await HomeLayoutStore.loadVisible();
    if (mounted) {
      setState(() {
        _visible = v;
        _loading = false;
      });
    }
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
                if (_visible.contains('logo'))
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, size: 72),
                  ),
                if (_visible.contains('logo')) const SizedBox(height: 20),
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
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      l10n.familyProfilesSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 24),
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
