import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import '../../app.dart';
import '../home_layout/home_layout_screen.dart';
import '../more/more_screen.dart';
import '../push_settings/push_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _textScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = LinkApp.maybeOf(context);
      if (app != null) setState(() => _textScale = app.currentTextScale);
    });
  }

  Future<void> _persistScale(double v) async {
    await LinkApp.maybeOf(context)?.setTextScaleFactor(v);
    if (mounted) setState(() => _textScale = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsSubtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Text(l10n.settingsTextSize, style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: _textScale,
            min: 0.85,
            max: 1.35,
            divisions: 10,
            label: '${(_textScale * 100).round()}%',
            onChanged: (v) => _persistScale(v),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text(l10n.pushSettingsTitle),
            subtitle: Text(l10n.pushSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(PushSettingsScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: Text(l10n.homeLayoutTitle),
            subtitle: Text(l10n.homeLayoutSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(HomeLayoutScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(l10n.moreStub),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(MoreScreen.routeName),
          ),
        ],
      ),
    );
  }
}
