import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/image_assets.dart';
import '../constants/storage_keys.dart';
import '../layout/link26_responsive_image_tokens.g.dart';
import '../layout/link26_responsive_layout.dart';
import '../layout/link26_responsive_ui_tokens.g.dart';
import '../theme/link26_surface_style.dart';
import '../widgets/decoded_asset_image.dart';
import 'hira_link_service.dart';

/// 매달 25일 1회 간편인증 안내 (simplelogin1 → simplelogin2).
abstract final class MonthlyHiraAuthGate {
  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static Future<void> maybeShow(BuildContext context) async {
    // 디버그(에뮬): 이미지 포함 다이얼로그가 첫 진입과 겹치면 ANR 체감 — 릴리즈/프로파일에서만 동작.
    if (kDebugMode) return;

    final now = DateTime.now();
    if (now.day != 25) return;

    final p = await SharedPreferences.getInstance();
    final key = _monthKey(now);
    if (p.getString(StorageKeys.hiraMonthlyAuthMonth) == key) return;
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final w = MediaQuery.sizeOf(ctx).width;
        final h1 = Link26ResponsiveImageHeights.simpleLogin1(w);
        final iw = Link26Layout.innerWidth(w);
        final w1 = Link26ResponsiveImageHeights.simpleLogin1DisplayWidth(w)
            .clamp(0.0, iw);
        return AlertDialog(
          title: Text(l10n.monthlyHiraTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.monthlyHiraBody),
                SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
                Center(
                  child: SizedBox(
                    width: w1,
                    child: DecodedAssetImage(
                      ImageAssets.simplelogin1,
                      height: h1,
                      fit: BoxFit.contain,
                      borderRadius:
                          BorderRadius.circular(Link26Surface.radiusInput),
                      errorBuilder: (context, error, stackTrace) =>
                          SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.later),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (!context.mounted) return;
                await _secondStep(context, l10n, key);
              },
              child: Text(l10n.monthlyHiraPrimaryAction),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _secondStep(
    BuildContext context,
    AppLocalizations l10n,
    String monthKey,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final w = MediaQuery.sizeOf(ctx).width;
        final h2 = Link26ResponsiveImageHeights.simpleLogin2(w);
        final iw = Link26Layout.innerWidth(w);
        final w2 = Link26ResponsiveImageHeights.simpleLogin2DisplayWidth(w)
            .clamp(0.0, iw);
        return AlertDialog(
          title: Text(l10n.monthlyHiraSecondTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: w2,
                    child: DecodedAssetImage(
                      ImageAssets.simplelogin2,
                      height: h2,
                      fit: BoxFit.contain,
                      borderRadius:
                          BorderRadius.circular(Link26Surface.radiusInput),
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
                Text(l10n.monthlyHiraSecondHint),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.later),
            ),
            FilledButton(
              onPressed: () async {
                final p = await SharedPreferences.getInstance();
                await p.setString(StorageKeys.hiraMonthlyAuthMonth, monthKey);
                await HiraLinkService.afterMonthlyEasyAuth();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(l10n.monthlyHiraComplete),
            ),
          ],
        );
      },
    );
  }
}
