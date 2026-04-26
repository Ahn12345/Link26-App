import 'package:flutter/material.dart';
import 'package:link_app/l10n/app_localizations.dart';

import 'ai_chat_models.dart';
import 'ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  static const routeName = '/ai-chat';

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _service = AiChatService();
  final _messageCtrl = TextEditingController();
  final _ocrCtrl = TextEditingController();
  ChatTriageResult? _triage;
  MedicineInsight? _insight;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _ocrCtrl.dispose();
    super.dispose();
  }

  Color _signalColor(SafetySignal signal, BuildContext context) {
    switch (signal) {
      case SafetySignal.green:
        return Colors.green;
      case SafetySignal.yellow:
        return Colors.orange;
      case SafetySignal.red:
        return Theme.of(context).colorScheme.error;
    }
  }

  Future<void> _runImageAnalysis() async {
    final text = _ocrCtrl.text.trim();
    if (text.isEmpty) return;
    final result = await _service.analyzePrescriptionImage(recognizedText: text);
    if (!mounted) return;
    setState(() => _insight = result);
  }

  void _runTriage() {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) return;
    setState(() => _triage = _service.triageMessage(message));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiChatTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.aiChatSubtitle),
          const SizedBox(height: 12),
          TextField(
            controller: _ocrCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.aiOcrInputLabel,
              hintText: l10n.aiOcrInputHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _runImageAnalysis,
            icon: const Icon(Icons.image_search),
            label: Text(l10n.aiAnalyzeImageButton),
          ),
          if (_insight != null) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.circle,
                  color: _signalColor(_insight!.signal, context),
                ),
                title: Text(_insight!.recommendation),
                subtitle: Text(_insight!.reason),
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _messageCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.aiSymptomInputLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _runTriage,
            icon: const Icon(Icons.chat),
            label: Text(l10n.aiPrimaryAnswerButton),
          ),
          if (_triage != null) ...[
            const SizedBox(height: 8),
            Card(
              color: _triage!.urgent ? Colors.red.shade50 : Colors.green.shade50,
              child: ListTile(
                title: Text(_triage!.primaryAnswer),
                subtitle: Text(_triage!.followUpPrompt),
                leading: Icon(
                  _triage!.urgent ? Icons.warning_amber : Icons.check_circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
