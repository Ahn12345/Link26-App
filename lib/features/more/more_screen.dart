import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../app.dart';
import '../../core/services/auth_session.dart';
import '../auth/auth_welcome_screen.dart';
import '../family_profiles/family_profiles_screen.dart';
import '../family_voice/family_voice_screen.dart';
import '../home_layout/home_layout_screen.dart';
import '../medicine_guide/medicine_guide_screen.dart';
import '../push_settings/push_settings_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const routeName = '/more';

  static const _familyVoiceAsset = 'assets/images/emergencycall.png';
  static const _familyProfilesAsset = 'assets/images/familyadd.png';
  static const _settingsAsset = 'assets/images/setting.png';
  static const _medicineAsset = 'assets/images/pillsearch.png';
  static const _searchAsset = 'assets/images/pillsearch.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = Link26App.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.moreStub),
          const SizedBox(height: 16),
          Text(
            l10n.moreMenuSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
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
          const Divider(height: 32),
          Text(l10n.language, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.languageSystem),
            leading: const Icon(Icons.language),
            onTap: () => app?.setLocaleOverride(null),
          ),
          ListTile(
            title: Text(l10n.languageEnglish),
            leading: const Icon(Icons.abc),
            onTap: () => app?.setLocaleOverride(const Locale('en')),
          ),
          ListTile(
            title: Text(l10n.languageKorean),
            leading: const Icon(Icons.translate),
            onTap: () => app?.setLocaleOverride(const Locale('ko')),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await AuthSession.signOut();
              if (context.mounted) {
                await Navigator.of(context).pushNamedAndRemoveUntil(
                  AuthWelcomeScreen.routeName,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
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
        onTap: () => Navigator.of(context).pushNamed(route),
      ),
    );
  }
}
