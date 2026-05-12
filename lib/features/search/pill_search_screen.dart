import 'package:flutter/material.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/constants/image_assets.dart';
import '../../core/design/link26_design_catalog.dart';
import '../../core/layout/link26_responsive_image_tokens.g.dart';
import '../../core/layout/link26_responsive_layout.dart';
import '../../core/layout/link26_responsive_ui_tokens.g.dart';
import '../../core/services/local_medicine_list_store.dart';
import '../../core/theme/link26_surface_style.dart';
import '../../core/theme/link26_unified_page.dart';
import '../../core/widgets/decoded_asset_image.dart';
import '../../core/widgets/link26_brand_backdrop.dart';
import '../../core/widgets/link26_dashboard_widgets.dart';
import '../../core/widgets/link26_standard_frame.dart';

/// 약 검색 + 내 약 목록에 추가 (`pillsearch.png`).
class PillSearchScreen extends StatefulWidget {
  const PillSearchScreen({super.key});

  static const routeName = '/pill-search';

  @override
  State<PillSearchScreen> createState() => _PillSearchScreenState();
}

class _PillSearchScreenState extends State<PillSearchScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, String>> _publicRows = [];
  bool _publicLoading = false;
  String? _publicError;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> _normalizeEasyDrug(dynamic root) {
    if (root is! Map) return [];
    final inner = (root['response'] is Map ? (root['response'] as Map)['body'] : null) ??
        root['body'];
    if (inner is! Map) return [];
    var items = inner['items'];
    if (items == null) return [];
    final list = items is List ? items : [items];
    return list.map((entry) {
      if (entry is Map && entry['item'] is Map) {
        return Map<String, String>.from(
          (entry['item'] as Map).map((k, v) => MapEntry('$k', '$v')),
        );
      }
      if (entry is Map) {
        return Map<String, String>.from(
          entry.map((k, v) => MapEntry('$k', '$v')),
        );
      }
      return <String, String>{};
    }).where((m) => m.isNotEmpty).toList();
  }

  Future<void> _searchPublic() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    if (!Link26BffIntegrationsClient.canCall) {
      setState(() {
        _publicError = null;
        _publicRows = [];
      });
      return;
    }
    setState(() {
      _publicLoading = true;
      _publicError = null;
      _publicRows = [];
    });
    try {
      final res = await Link26BffIntegrationsClient.searchEasyDrug(
        itemName: q,
        numOfRows: 15,
      );
      final data = res?['data'];
      setState(() {
        _publicRows = _normalizeEasyDrug(data);
        if (_publicRows.isEmpty && res?['ok'] == true) {
          _publicError = 'empty';
        }
      });
    } catch (e) {
      setState(() => _publicError = '$e');
    } finally {
      if (mounted) setState(() => _publicLoading = false);
    }
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
    final w = MediaQuery.sizeOf(context).width;
    final heroH = Link26ResponsiveImageHeights.pillSearch(w);
    final inner = Link26Layout.innerWidth(w);
    final heroW = Link26ResponsiveImageHeights.pillSearchDisplayWidth(w)
        .clamp(0.0, inner);
    final topUnderAppBar =
        MediaQuery.viewPaddingOf(context).top + kToolbarHeight;
    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Link26Surface.textPrimary,
        title: Text(
          l10n.pillSearchTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Link26BrandBackdrop(
        solidBackground: Link26UnifiedPage.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: topUnderAppBar),
            child: Link26StandardFrame(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: Link26Layout.pageInsets(w).bottom,
                ),
                children: [
                  Link26FramedPageCard(
                    padding: EdgeInsets.symmetric(
                      vertical: Link26ResponsiveUi.authCardPadVertical(w),
                      horizontal:
                          Link26ResponsiveUi.authCardPadHorizontal(w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Center(
                        child: SizedBox(
                          width: heroW,
                          height: heroH,
                          child: DecodedAssetImage(
                            Link26DesignCatalog.heroAssetPath(
                                'pillsearch', ImageAssets.pillsearch),
                            width: heroW,
                            height: heroH,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(
                              Link26Surface.radiusInput,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: Link26ResponsiveUi.heroArtToContent(w)),
                      TextField(
                        controller: _ctrl,
                        decoration: Link26Surface.inputDecoration(
                          labelText: l10n.pillSearchLabel,
                          hintText: l10n.pillSearchHint,
                        ),
                        style: TextStyle(
                          color: Link26Surface.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: Link26ResponsiveUi.body(w),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapLg(w)),
                      FilledButton.icon(
                        onPressed: _add,
                        style: Link26UnifiedPage.filledCtaButton(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.homeAddMedicine),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                      Text(
                        l10n.pillSearchPublicDataTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: Link26ResponsiveUi.body(w),
                          color: Link26Surface.textPrimary,
                        ),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                      Text(
                        l10n.pillSearchPublicDataEmpty,
                        style: TextStyle(
                          fontSize: Link26ResponsiveUi.caption(w),
                          color: Link26Surface.textSecondary,
                        ),
                      ),
                      SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                      OutlinedButton.icon(
                        onPressed: _publicLoading ? null : _searchPublic,
                        icon: const Icon(Icons.search),
                        label: Text(l10n.pillSearchTitle),
                      ),
                      if (_publicLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (_publicError != null && _publicError != 'empty')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _publicError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: Link26ResponsiveUi.caption(w),
                            ),
                          ),
                        ),
                      ..._publicRows.map((row) {
                        final name = row['itemName'] ?? '';
                        return ListTile(
                          dense: true,
                          title: Text(
                            name.isEmpty ? '—' : name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: Link26ResponsiveUi.body(w),
                            ),
                          ),
                          subtitle: row['efcyQesitm'] != null &&
                                  row['efcyQesitm']!.isNotEmpty
                              ? Text(
                                  row['efcyQesitm']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: Link26ResponsiveUi.caption(w),
                                  ),
                                )
                              : null,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () async {
                            if (name.isEmpty) return;
                            _ctrl.text = name;
                            await _add();
                          },
                        );
                      }),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
