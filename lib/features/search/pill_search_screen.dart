import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/constants/image_assets.dart';
import '../../core/services/local_medicine_list_store.dart';
import '../../core/theme/link26_surface_style.dart';
import '../../core/widgets/decoded_asset_image.dart';
import '../../core/widgets/link26_dashboard_widgets.dart';

/// 약 검색 + 내 약 목록에 추가 (`pillsearch.png`).
class PillSearchScreen extends StatefulWidget {
  const PillSearchScreen({super.key});

  static const routeName = '/pill-search';

  @override
  State<PillSearchScreen> createState() => _PillSearchScreenState();
}

class _PillSearchScreenState extends State<PillSearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    await LocalMedicineListStore.add(_ctrl.text);
    if (!mounted) return;
    _ctrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).pillSearchAdded)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pillSearchTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Link26ElevatedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecodedAssetImage(
                    ImageAssets.pillsearch,
                    height: 160,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(12),
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    decoration: Link26Surface.inputDecoration(
                      labelText: l10n.pillSearchLabel,
                      hintText: l10n.pillSearchHint,
                    ),
                    style: const TextStyle(color: Link26Surface.textPrimary, fontWeight: FontWeight.w600),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _add,
              style: Link26Surface.filledAccentButton(minimumSize: const Size(double.infinity, 52)),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeAddMedicine),
            ),
          ],
        ),
      ),
    );
  }
}
