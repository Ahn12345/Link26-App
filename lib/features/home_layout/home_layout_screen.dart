import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import '../../core/services/home_layout_store.dart';

class HomeLayoutScreen extends StatefulWidget {
  const HomeLayoutScreen({super.key});

  static const routeName = '/home-layout';

  @override
  State<HomeLayoutScreen> createState() => _HomeLayoutScreenState();
}

class _HomeLayoutScreenState extends State<HomeLayoutScreen> {
  Set<String> _visible = {...HomeLayoutStore.allBlockIds};
  bool _loading = true;

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

  Future<void> _save() async {
    await HomeLayoutStore.saveVisible(_visible);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).save)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homeLayoutTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeLayoutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.homeLayoutSubtitle),
          const SizedBox(height: 8),
          Text(l10n.homeLayoutHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ...HomeLayoutStore.allBlockIds.map((id) {
            return CheckboxListTile(
              value: _visible.contains(id),
              onChanged: (on) {
                setState(() {
                  if (on == true) {
                    _visible = {..._visible, id};
                  } else {
                    _visible = {..._visible}..remove(id);
                  }
                });
              },
              title: Text(id),
            );
          }),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
    );
  }
}
