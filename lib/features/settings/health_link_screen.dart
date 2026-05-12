import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/tilko/tilko_env.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 틸코 간편인증 → (BFF에서) CODEF 건강iN 진료·투약 조회 플로우.
class HealthLinkScreen extends StatefulWidget {
  const HealthLinkScreen({super.key});

  static const routeName = '/settings/health-link';

  @override
  State<HealthLinkScreen> createState() => _HealthLinkScreenState();
}

class _HealthLinkScreenState extends State<HealthLinkScreen> {
  final _privateAuthType = TextEditingController(text: 'KAKAO');
  final _userName = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _rrn = TextEditingController();
  final _codefJson = TextEditingController(text: '{}');
  String? _result;
  bool _busy = false;

  @override
  void dispose() {
    _privateAuthType.dispose();
    _userName.dispose();
    _birthDate.dispose();
    _phone.dispose();
    _rrn.dispose();
    _codefJson.dispose();
    super.dispose();
  }

  Map<String, dynamic> _tilkoBody() => {
        'PrivateAuthType': _privateAuthType.text.trim(),
        'UserName': _userName.text.trim(),
        'BirthDate': _birthDate.text.trim(),
        'UserCellphoneNumber': _phone.text.trim(),
        'IdentityNumber': _rrn.text.trim(),
      };

  Future<void> _runFlow(bool codefToo) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      Map<String, dynamic>? codefPayload;
      try {
        final decoded = jsonDecode(_codefJson.text.trim());
        if (decoded is Map<String, dynamic>) {
          codefPayload = decoded;
        }
      } catch (_) {
        if (codefToo) {
          setState(() {
            _result = 'CODEF JSON 파싱 실패';
            _busy = false;
          });
          return;
        }
      }

      if (Link26BffIntegrationsClient.canCall) {
        if (codefToo) {
          final res = await Link26BffIntegrationsClient.flowTilkoCodefTreatment(
            tilko: _tilkoBody(),
            codefPayload: codefPayload,
          );
          setState(() => _result = res == null
              ? '응답 없음'
              : const JsonEncoder.withIndent('  ').convert(res));
        } else {
          final res =
              await Link26BffIntegrationsClient.tilkoHiraSimpleAuth(_tilkoBody());
          setState(() => _result = res == null
              ? '응답 없음'
              : const JsonEncoder.withIndent('  ').convert(res));
        }
        return;
      }

      if (!TilkoEnv.isConfigured) {
        setState(() => _result = '${l10n.healthLinkBffHint}\n${l10n.healthLinkDirectHint}');
        return;
      }

      final client = TilkoHiraSimpleAuthClient(
        apiKey: TilkoEnv.apiKey,
        apiHost: TilkoEnv.apiHost,
      );
      final tilkoRes = await client.requestFromJsonMap(_tilkoBody());
      if (codefToo) {
        setState(() {
          _result =
              '${const JsonEncoder.withIndent('  ').convert(tilkoRes)}\n\n'
              '(CODEF는 BFF(NHIS_BASE_URL)에서만 연동합니다.)';
        });
      } else {
        setState(() => _result = const JsonEncoder.withIndent('  ').convert(tilkoRes));
      }
    } catch (e, st) {
      setState(() => _result = '$e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final useBff = Link26BffIntegrationsClient.canCall;
    final mock = NhisRuntimeConfig.useMock;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthLinkTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.healthLinkSubtitle),
          const SizedBox(height: 8),
          Text(
            useBff
                ? '${l10n.healthLinkBffHint}'
                    '${mock ? ' NHIS_USE_MOCK=true 이면 가입·로그인·복약 동기화만 목 동작입니다.' : ''}'
                : l10n.healthLinkDirectHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _privateAuthType,
            decoration: const InputDecoration(labelText: 'PrivateAuthType'),
          ),
          TextField(controller: _userName, decoration: const InputDecoration(labelText: 'UserName')),
          TextField(
            controller: _birthDate,
            decoration: const InputDecoration(labelText: 'BirthDate (YYYYMMDD)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'UserCellphoneNumber'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: _rrn,
            decoration: const InputDecoration(labelText: 'IdentityNumber'),
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codefJson,
            decoration: InputDecoration(labelText: l10n.healthLinkJsonLabel),
            maxLines: 5,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _runFlow(true),
            child: Text(l10n.healthLinkFlowCta),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _runFlow(false),
            child: Text(l10n.healthLinkTilkoOnlyCta),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_result != null) ...[
            const SizedBox(height: 16),
            SelectableText(_result!, style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
