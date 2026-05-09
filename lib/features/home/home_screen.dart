import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/services/home_layout_store.dart';
import '../../core/widgets/widgets.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../family_profiles/family_profiles_screen.dart';
import '../family_voice/family_voice_screen.dart';
import '../home_layout/home_layout_screen.dart';
import '../medicine_guide/medicine_guide_screen.dart';
import '../more/more_screen.dart';
import '../push_settings/push_settings_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> _visible = {...HomeLayoutStore.allBlockIds};
  bool _layoutLoading = true;

  static const _homeHeroAsset = 'assets/images/Home.png';
  static const _aiChatAsset = 'assets/images/aichat.png';
  static const _familyVoiceAsset = 'assets/images/emergencycall.png';
  static const _familyProfilesAsset = 'assets/images/familyadd.png';
  static const _settingsAsset = 'assets/images/setting.png';
  static const _medicineAsset = 'assets/images/pillsearch.png';
  static const _searchAsset = 'assets/images/pillsearch.png';

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final v = await HomeLayoutStore.loadVisible();
    if (mounted) {
      setState(() {
        _visible = v;
        _layoutLoading = false;
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
          onRefresh: _loadLayout,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_layoutLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                if (_visible.contains('logo'))
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('logo1: $error');
                      return const Icon(Icons.image, size: 80);
                    },
                  ),
                if (_visible.contains('logo')) const SizedBox(height: 24),
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
                if (_visible.contains('quickActions')) ...[
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
                  _navTile(
                    context,
                    l10n.aiChatTitle,
                    l10n.aiChatSubtitle,
                    Icons.smart_toy,
                    AiChatScreen.routeName,
                    leadingAsset: _aiChatAsset,
                  ),
                  _navTile(
                    context,
                    l10n.familyVoiceTitle,
                    l10n.familyVoiceSubtitle,
                    Icons.call,
                    FamilyVoiceScreen.routeName,
                    leadingAsset: _familyVoiceAsset,
                  ),
                  _navTile(
                    context,
                    l10n.familyProfilesTitle,
                    l10n.familyProfilesSubtitle,
                    Icons.groups,
                    FamilyProfilesScreen.routeName,
                    leadingAsset: _familyProfilesAsset,
                  ),
                  _navTile(
                    context,
                    l10n.settingsTitle,
                    l10n.settingsSubtitle,
                    Icons.settings,
                    SettingsScreen.routeName,
                    leadingAsset: _settingsAsset,
                  ),
                  _navTile(
                    context,
                    l10n.pushSettingsTitle,
                    l10n.pushSettingsSubtitle,
                    Icons.notifications_active,
                    PushSettingsScreen.routeName,
                  ),
                  _navTile(
                    context,
                    l10n.homeLayoutTitle,
                    l10n.homeLayoutSubtitle,
                    Icons.dashboard_customize,
                    HomeLayoutScreen.routeName,
                  ),
                  _navTile(
                    context,
                    l10n.medicineGuideTitle,
                    l10n.medicineGuideSubtitle,
                    Icons.medication,
                    MedicineGuideScreen.routeName,
                    leadingAsset: _medicineAsset,
                  ),
                  _navTile(
                    context,
                    l10n.searchTitle,
                    l10n.searchStub,
                    Icons.search,
                    SearchScreen.routeName,
                    leadingAsset: _searchAsset,
                  ),
                  _navTile(
                    context,
                    l10n.moreTitle,
                    l10n.moreStub,
                    Icons.more_horiz,
                    MoreScreen.routeName,
                  ),
                ],
                const SizedBox(height: 24),
                if (_visible.contains('quickActions'))
                  PrimaryButton(
                    label: l10n.reload,
                    icon: Icons.refresh,
                    onPressed: _loadLayout,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route, {
    String? leadingAsset,
  }) {
    final leading = leadingAsset == null
        ? Icon(icon)
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              leadingAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('tile asset $leadingAsset: $error');
                return Icon(icon);
              },
            ),
          );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(route).then((_) => _loadLayout());
        },
      ),
    );
  }
}
