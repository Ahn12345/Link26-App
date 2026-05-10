import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:link26_app/core/constants/storage_keys.dart';
import 'package:link26_app/models/link_models.dart';

/// AI 채팅 일일 한도·말풍선 로컬 저장 (탭 이동·재실행 후에도 유지).
abstract final class AiChatLocalStore {
  AiChatLocalStore._();

  /// 앱·기획 문구와 동일: 매일 **04:00 (로컬)** 을 하루 경계로 쓴 날짜 키.
  static String quotaDayKey(DateTime now) {
    final shifted = now.subtract(const Duration(hours: 4));
    return '${shifted.year}-${shifted.month.toString().padLeft(2, '0')}-'
        '${shifted.day.toString().padLeft(2, '0')}';
  }

  static Future<int> loadDailyUsed() async {
    final p = await SharedPreferences.getInstance();
    final day = quotaDayKey(DateTime.now());
    final stored = p.getString(StorageKeys.aiChatQuotaDayV1);
    if (stored != day) {
      await p.setString(StorageKeys.aiChatQuotaDayV1, day);
      await p.setInt(StorageKeys.aiChatQuotaUsedV1, 0);
      return 0;
    }
    return p.getInt(StorageKeys.aiChatQuotaUsedV1) ?? 0;
  }

  static Future<void> saveDailyUsed(int used) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      StorageKeys.aiChatQuotaDayV1,
      quotaDayKey(DateTime.now()),
    );
    await p.setInt(StorageKeys.aiChatQuotaUsedV1, used);
  }

  static Future<List<ChatMessage>> loadMessages() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(StorageKeys.aiChatMessagesJsonV1);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMessages(List<ChatMessage> list) async {
    final p = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((m) => m.toJson()).toList());
    await p.setString(StorageKeys.aiChatMessagesJsonV1, raw);
  }

  static Future<void> clearMessages() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.aiChatMessagesJsonV1);
  }
}
