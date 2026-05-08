import 'package:flutter/material.dart';
import 'package:link26_app/domain/domain.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import 'data/local_medicine_catalog_repository.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  static const routeName = '/medicine';

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final MedicineCatalogRepository _repo = const LocalMedicineCatalogRepository();
  late Future<List<MedicineProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listKnown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicineCatalogTitle),
        actions: [
          IconButton(
            tooltip: l10n.medicineCatalogTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _future = _repo.listKnown());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MedicineProduct>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(child: Text(l10n.medicineCatalogEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text(
                  l10n.medicineCatalogSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              final m = items[i - 1];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(m.name),
                  subtitle: m.dosageHint != null ? Text(m.dosageHint!) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
