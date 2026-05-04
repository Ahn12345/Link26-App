import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_text_field.dart';

class SymptomInputPanel extends StatelessWidget {
  const SymptomInputPanel({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: controller,
          label: l10n.aiSymptomInputLabel,
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.chat),
          label: Text(l10n.aiPrimaryAnswerButton),
        ),
      ],
    );
  }
}
