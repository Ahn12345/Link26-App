import 'package:flutter/material.dart';
import 'package:link26_app/core/constants/legal_assets.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:pdfx/pdfx.dart';

/// 번들된 개인정보 수집·이용 동의서 PDF.
class PrivacyConsentPdfScreen extends StatefulWidget {
  const PrivacyConsentPdfScreen({super.key});

  @override
  State<PrivacyConsentPdfScreen> createState() =>
      _PrivacyConsentPdfScreenState();
}

class _PrivacyConsentPdfScreenState extends State<PrivacyConsentPdfScreen> {
  late final PdfController _pdfController = PdfController(
    document: PdfDocument.openAsset(LegalAssets.privacyConsentPdf),
  );

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      appBar: AppBar(
        backgroundColor: Link26UnifiedPage.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Link26Surface.textPrimary,
        elevation: 0,
        title: Text(
          l10n.privacyConsentDocumentTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: PdfView(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
        pageSnapping: false,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
          pageLoaderBuilder: (_) => const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorBuilder: (_, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${l10n.privacyConsentOpenFailed}\n\n$error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Link26Surface.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
