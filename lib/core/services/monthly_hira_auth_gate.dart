import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/image_assets.dart';
import '../constants/storage_keys.dart';
import 'hira_link_service.dart';

/// 매달 25일 1회 간편인증 안내 (simplelogin1 → simplelogin2).
abstract final class MonthlyHiraAuthGate {
  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static Future<void> maybeShow(BuildContext context) async {
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
      builder: (ctx) => AlertDialog(
        title: Text(l10n.monthlyHiraTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.monthlyHiraBody),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  ImageAssets.simplelogin1,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 8),
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
      ),
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
      builder: (ctx) => AlertDialog(
        title: Text(l10n.monthlyHiraSecondTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  ImageAssets.simplelogin2,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
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
      ),
    );
  }
}
