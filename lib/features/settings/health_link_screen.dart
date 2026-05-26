import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:link26_app/core/constants/link26_medication_feature_flags.dart';
import 'package:link26_app/core/services/nhis_medicines_sync.dart';
import 'package:link26_app/integrations/bff/link26_bff_integrations_client.dart';
import 'package:link26_app/integrations/codef/codef_medication_mapper.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/integrations/tilko/tilko_env.dart';
import 'package:link26_app/integrations/tilko/tilko_hira_simple_auth_client.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/models/medicine.dart';

/// 틸코 간편인증 → BFF 심평원 **내가 먹는 약** 등 복약 플로우(개발·설정 화면).
class HealthLinkScreen extends StatefulWidget {
  const HealthLinkScreen({super.key});

  static const routeName = '/settings/health-link';

  @override
  State<HealthLinkScreen> createState() => _HealthLinkScreenState();
}

class _HealthLinkScreenState extends State<HealthLinkScreen> {
  final _privateAuthType = TextEditingController(text: 'PASS');
  final _userName = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _rrn = TextEditingController();
  final _bffExtraJson = TextEditingController(text: '{}');
  String? _result;
  bool _busy = false;

  @override
  void dispose() {
    _privateAuthType.dispose();
    _userName.dispose();
    _birthDate.dispose();
    _phone.dispose();
    _rrn.dispose();
    _bffExtraJson.dispose();
    super.dispose();
  }

  Map<String, dynamic> _tilkoBody() => {
        'PrivateAuthType': _privateAuthType.text.trim(),
        'UserName': _userName.text.trim(),
        'BirthDate': _birthDate.text.trim(),
        'UserCellphoneNumber': _phone.text.trim(),
        'IdentityNumber': _rrn.text.trim(),
      };

  /// BFF 전체 플로우가 성공하면 로컬 복약 캐시에 반영합니다(홈 목록과 동일).
  Future<void> _persistMedicinesIfFlowOk(Map<String, dynamic>? res) async {
    if (res == null || res['ok'] != true) return;
    Map<String, dynamic>? metaMap;
    final meta = res['meta'];
    if (meta is Map) {
      metaMap = Map<String, dynamic>.from(
        meta.map((k, v) => MapEntry('$k', v)),
      );
    }
    final source = metaMap?['source'] as String?;
    final itemsRaw = res['items'];
    final list = itemsRaw is List ? itemsRaw : const <dynamic>[];
    final medicines = <Medicine>[];
    for (final e in list) {
      if (e is Map) {
        medicines.add(Medicine.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    if (medicines.isEmpty) {
      dynamic rootRaw = res['hira_medications'];
      if (rootRaw is! Map) rootRaw = res['nhis_treatment_injection'];
      if (rootRaw is Map) {
        final rootMap = Map<String, dynamic>.from(
          rootRaw.map((k, v) => MapEntry('$k', v)),
        );
        for (final row in codefRootToMedicationItems(rootMap)) {
          medicines.add(Medicine.fromJson(row));
        }
      }
    }
    final noteRaw = metaMap?['note'] ?? metaMap?['notice'];
    final noteStr = noteRaw is String ? noteRaw.trim() : '';
    await NhisMedicinesSync.applyRemoteMedicines(
      medicines: medicines,
      metaSource: source,
      codefResultCode: metaMap?['codefResultCode'] as String?,
      codefResultMessage: metaMap?['codefResultMessage'] as String?,
      metaNote: noteStr.isEmpty ? null : noteStr,
    );
  }

  Future<void> _runFlow(bool fullMedicationFlow) async {
    final l10n = AppLocalizations.of(context);
    if (!Link26MedicationFeatureFlags.tilkoHiraRemoteSyncEnabled) {
      setState(() {
        _result =
            '틸코·BFF 심평원 API는 일시 중단되었습니다.\n'
            '홈 「처방전 촬영 등록」을 사용하세요.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      Map<String, dynamic>? flowExtras;
      try {
        final decoded = jsonDecode(_bffExtraJson.text.trim());
        if (decoded is Map<String, dynamic>) {
          flowExtras = decoded;
        }
      } catch (_) {
        if (fullMedicationFlow) {
          setState(() {
            _result = '추가 JSON 파싱 실패(BFF flow_extras 객체 형식을 확인하세요)';
            _busy = false;
          });
          return;
        }
      }

      if (Link26BffIntegrationsClient.canCall) {
        if (fullMedicationFlow) {
          final res = await Link26BffIntegrationsClient.flowTilkoHiraMedications(
            tilko: _tilkoBody(),
            flowExtras: flowExtras,
          );
          if (mounted) {
            await _persistMedicinesIfFlowOk(res);
            if (res != null && res['ok'] == true && mounted) {
              final list = res['items'];
              final n = list is List ? list.length : 0;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('내 약 목록 갱신: $n건 (홈에서 확인)')),
              );
            }
          }
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
      if (fullMedicationFlow) {
        setState(() {
          _result =
              '${const JsonEncoder.withIndent('  ').convert(tilkoRes)}\n\n'
              '(심평원 복약 전체 조회는 BFF(NHIS_BASE_URL)에서만 가능합니다.)';
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
            controller: _bffExtraJson,
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
