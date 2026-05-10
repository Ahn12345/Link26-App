import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/constants/image_assets.dart';
import '../../core/layout/link26_responsive_image_tokens.g.dart';
import '../../core/layout/link26_responsive_layout.dart';
import '../../core/layout/link26_responsive_ui_tokens.g.dart';
import '../../core/theme/link26_surface_style.dart';
import '../../core/widgets/decoded_asset_image.dart';

/// 디자인 에셋 `emergencycall.png` — 긴급 연락 UX (실제 전화는 추후 `tel:` 연동).
class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});

  static const routeName = '/emergency-contact';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final heroH = Link26ResponsiveImageHeights.emergencyIllustration(w);
    final inner = Link26Layout.innerWidth(w);
    final heroW = Link26ResponsiveImageHeights.emergencyIllustrationDisplayWidth(w)
        .clamp(0.0, inner);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEmergencyContact)),
      body: SafeArea(
        child: Link26ResponsiveScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: heroW,
                  child: DecodedAssetImage(
                    ImageAssets.emergencycall,
                    height: heroH,
                    fit: BoxFit.contain,
                    borderRadius:
                        BorderRadius.circular(Link26Surface.radiusInput),
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.phone_in_talk, size: 120),
                  ),
                ),
              ),
              SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
              Text(
                l10n.emergencyContactStub,
                style: TextStyle(
                  fontSize: Link26ResponsiveUi.body(w),
                  color: Link26Surface.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.emergencyCallPlaceholder)),
                  );
                },
                icon: const Icon(Icons.call),
                label: Text(l10n.emergencyCallAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
