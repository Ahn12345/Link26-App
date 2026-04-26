import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import '../../app.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const routeName = '/more';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = LinkApp.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.moreStub),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }
}
