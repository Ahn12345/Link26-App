import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_text_field.dart';

class OcrInputPanel extends StatelessWidget {
  const OcrInputPanel({
    super.key,
    required this.controller,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: controller,
          label: l10n.aiOcrInputLabel,
          hint: l10n.aiOcrInputHint,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onAnalyze,
          icon: const Icon(Icons.image_search),
          label: Text(l10n.aiAnalyzeImageButton),
        ),
      ],
    );
  }
}
