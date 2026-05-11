import 'package:flutter/material.dart';
import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/services/auth_session.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// CODEF `connectedId` 저장 — BFF `/v1/medications` 쿼리로 전달됩니다.
class CodefConnectionScreen extends StatefulWidget {
  const CodefConnectionScreen({super.key});

  static const routeName = '/settings/codef-connection';

  @override
  State<CodefConnectionScreen> createState() => _CodefConnectionScreenState();
}

class _CodefConnectionScreenState extends State<CodefConnectionScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  String? _phoneDigits;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phone = await AuthSession.activePhoneDigits();
    if (!mounted) return;
    if (phone == null || phone.length < 10) {
      setState(() {
        _loading = false;
        _phoneDigits = phone;
      });
      return;
    }
    final user = await UserLocalRepository.findUserByPhone(phone);
    if (!mounted) return;
    _controller.text = user?.codefConnectedId ?? '';
    setState(() {
      _loading = false;
      _phoneDigits = phone;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final phone = _phoneDigits;
    if (phone == null || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsCodefConnectionPhoneRequired)),
      );
      return;
    }
    await UserLocalRepository.updateCodefConnectedId(
      phone,
      connectedId: _controller.text.trim().isEmpty ? null : _controller.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsCodefConnectionSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCodefConnectionTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.settingsCodefConnectionSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: l10n.settingsCodefConnectedIdLabel,
                    hintText: l10n.settingsCodefConnectionHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _save,
                  child: Text(l10n.save),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    _controller.clear();
                  },
                  child: Text(l10n.settingsCodefConnectionClear),
                ),
              ],
            ),
    );
  }
}
