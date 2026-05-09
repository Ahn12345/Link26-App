import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 오늘의 알림 전체 보기 — 데모 체크리스트 (추후 FCM·스케줄 연동).
class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});

  static const routeName = '/alerts';

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  final _items = <String, bool>{
    'water': false,
    'vitamin': false,
    'walk': false,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.alertsScreenTitle)),
      body: ListView(
        children: [
          CheckboxListTile(
            value: _items['water'],
            onChanged: (v) => setState(() => _items['water'] = v ?? false),
            title: Text(l10n.alertItemWater),
          ),
          CheckboxListTile(
            value: _items['vitamin'],
            onChanged: (v) => setState(() => _items['vitamin'] = v ?? false),
            title: Text(l10n.alertItemVitamin),
          ),
          CheckboxListTile(
            value: _items['walk'],
            onChanged: (v) => setState(() => _items['walk'] = v ?? false),
            title: Text(l10n.alertItemWalk),
          ),
        ],
      ),
    );
  }
}
