import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../app.dart';
import '../auth/auth_welcome_screen.dart';
import '../family_profiles/family_profiles_screen.dart';
import '../family_voice/family_voice_screen.dart';
import '../home_layout/home_layout_screen.dart';
import '../medicine_guide/medicine_guide_screen.dart';
import '../more/more_screen.dart';
import '../push_settings/push_settings_screen.dart';
import '../search/search_screen.dart';
import 'emergency_contact_screen.dart';
import 'settings_screen.dart';
import '../../core/services/auth_session.dart';

/// 하단 탭 「설정」— 긴급연락·가족 추가·기타 메뉴.
class SettingsTabScreen extends StatelessWidget {
  const SettingsTabScreen({super.key});

  static const _familyVoiceAsset = 'assets/images/emergencycall.png';
  static const _familyProfilesAsset = 'assets/images/familyadd.png';
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = Link26App.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.phone_in_talk),
            title: Text(l10n.settingsEmergencyContact),
            subtitle: Text(l10n.settingsEmergencyContactSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .pushNamed(EmergencyContactScreen.routeName),
          ),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _familyProfilesAsset,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.groups),
              ),
            ),
            title: Text(l10n.settingsFamilyAddEntry),
            subtitle: Text(l10n.familyProfilesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .pushNamed(FamilyProfilesScreen.routeName),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.settingsTextSize),
            subtitle: Text(l10n.settingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
          ),
          _imgTile(
            context,
            l10n.familyVoiceTitle,
            l10n.familyVoiceSubtitle,
            FamilyVoiceScreen.routeName,
            _familyVoiceAsset,
          ),
          _imgTile(
            context,
            l10n.pushSettingsTitle,
            l10n.pushSettingsSubtitle,
            PushSettingsScreen.routeName,
            null,
            icon: Icons.notifications_active,
          ),
          _imgTile(
            context,
            l10n.homeLayoutTitle,
            l10n.homeLayoutSubtitle,
            HomeLayoutScreen.routeName,
            null,
            icon: Icons.dashboard_customize,
          ),
          _imgTile(
            context,
            l10n.medicineGuideTitle,
            l10n.medicineGuideSubtitle,
            MedicineGuideScreen.routeName,
            null,
            icon: Icons.medication,
          ),
          _imgTile(
            context,
            l10n.searchTitle,
            l10n.searchStub,
            SearchScreen.routeName,
            null,
            icon: Icons.search,
          ),
          const Divider(height: 32),
          Text(l10n.language, style: Theme.of(context).textTheme.titleSmall),
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
          ListTile(
            leading: const Icon(Icons.more_horiz),
            title: Text(l10n.moreTitle),
            subtitle: Text(l10n.moreStub),
            onTap: () => Navigator.of(context).pushNamed(MoreScreen.routeName),
          ),
          const SizedBox(height: 16),
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

  Widget _imgTile(
    BuildContext context,
    String title,
    String subtitle,
    String route,
    String? asset, {
    IconData? icon,
  }) {
    return ListTile(
      leading: asset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                asset,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(icon ?? Icons.folder, size: 40),
              ),
            )
          : Icon(icon ?? Icons.chevron_right),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pushNamed(route),
    );
  }
}
