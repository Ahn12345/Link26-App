import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  static const routeName = '/search';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.searchStub),
      ),
    );
  }
}
