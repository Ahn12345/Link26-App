import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:link26_app/core/constants/storage_keys.dart';
import 'package:link26_app/models/link_models.dart';

/// AI 채팅 말풍선 — 로컬 SQLite (`link26_ai_chat.db`).
abstract final class AiChatMessageRepository {
  AiChatMessageRepository._();

  static Database? _db;
  static bool _prefsMigrationAttempted = false;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'link26_ai_chat.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ai_chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            time_label TEXT NOT NULL,
            card_title TEXT,
            card_subtitle TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static ChatMessage _rowToMessage(Map<String, Object?> row) {
    return ChatMessage(
      text: row['text'] as String? ?? '',
      isUser: (row['is_user'] as int? ?? 0) != 0,
      time: row['time_label'] as String? ?? '',
      cardTitle: row['card_title'] as String?,
      cardSubtitle: row['card_subtitle'] as String?,
    );
  }

  static Future<void> _migrateFromSharedPreferencesIfNeeded(
    Database db,
  ) async {
    if (_prefsMigrationAttempted) return;
    _prefsMigrationAttempted = true;

    final countRows =
        await db.rawQuery('SELECT COUNT(*) as c FROM ai_chat_messages');
    final n = (countRows.first['c'] as int?) ?? 0;
    if (n > 0) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.aiChatMessagesJsonV1);
    if (raw == null || raw.isEmpty) return;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final messages = list
          .map(
            (e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      if (messages.isEmpty) return;
      await db.transaction((txn) async {
        for (final m in messages) {
          await txn.insert('ai_chat_messages', {
            'text': m.text,
            'is_user': m.isUser ? 1 : 0,
            'time_label': m.time,
            'card_title': m.cardTitle,
            'card_subtitle': m.cardSubtitle,
          });
        }
      });
      await prefs.remove(StorageKeys.aiChatMessagesJsonV1);
    } catch (_) {
      // 손상된 JSON은 건너뜀
    }
  }

  /// 저장된 순서대로 전체 대화를 불러옵니다.
  static Future<List<ChatMessage>> loadMessages() async {
    final db = await _open();
    await _migrateFromSharedPreferencesIfNeeded(db);
    final rows = await db.query('ai_chat_messages', orderBy: 'id ASC');
    return rows.map(_rowToMessage).toList();
  }

  /// 현재 메모리 대화와 동일하게 DB를 덮어씁니다(단일 스레드 UI 모델과 동일).
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    final db = await _open();
    await _migrateFromSharedPreferencesIfNeeded(db);
    await db.transaction((txn) async {
      await txn.delete('ai_chat_messages');
      for (final m in messages) {
        await txn.insert('ai_chat_messages', {
          'text': m.text,
          'is_user': m.isUser ? 1 : 0,
          'time_label': m.time,
          'card_title': m.cardTitle,
          'card_subtitle': m.cardSubtitle,
        });
      }
    });
  }

  static Future<void> clearMessages() async {
    final db = await _open();
    await db.delete('ai_chat_messages');
  }
}
