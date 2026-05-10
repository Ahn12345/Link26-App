import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:link26_app/core/domain/result.dart';
import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/integrations/nhis/nhis_http_message.dart';
import 'package:link26_app/integrations/nhis/nhis_medications_client.dart';
import 'package:link26_app/integrations/nhis/nhis_medications_parser.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/models/medicine.dart';

enum NhisMedicinesSyncResult { skipped, success, failed }

/// BFF 복약 목록을 내려받아 로컬 캐시·약 이름 목록과 병합합니다.
abstract final class NhisMedicinesSync {
  static String _norm(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static Future<NhisMedicinesSyncResult> syncNow({
    required String phoneDigits,
  }) async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    if (NhisRuntimeConfig.baseUrl.isEmpty) {
      return NhisMedicinesSyncResult.skipped;
    }

    final client = NhisMedicationsClient();
    final result = await client.fetchMedicationsRaw(phoneDigits: phoneDigits);

    if (result is Failure<String>) {
      final msg = nhisHttpUserMessage(result.error);
      debugPrint(
        'NHIS medications GET 실패: $msg (base=${NhisRuntimeConfig.baseUrl} path=${NhisRuntimeConfig.medicinesPath})',
      );
      return NhisMedicinesSyncResult.failed;
    }

    final body = (result as Success<String>).data;
    final fromApi = NhisMedicationsParser.parseResponseBody(body);
    await _mergeIntoLocal(fromApi);
    return NhisMedicinesSyncResult.success;
  }

  static Future<void> _mergeIntoLocal(List<Medicine> fromApi) async {
    final cached = await NhisMedicineCacheStore.loadMedicines();
    final manualNames = await LocalMedicineListStore.load();

    final byName = <String, Medicine>{};
    for (final m in cached) {
      final k = _norm(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final m in fromApi) {
      final k = _norm(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final n in manualNames) {
      final k = _norm(n);
      if (k.isEmpty) continue;
      byName.putIfAbsent(
        k,
        () => Medicine(name: n.trim(), dose: '-', frequency: '-', time: '-'),
      );
    }

    final merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    await NhisMedicineCacheStore.saveMedicines(merged);

    for (final m in merged) {
      await LocalMedicineListStore.add(m.name);
    }
  }
}
