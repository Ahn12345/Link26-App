import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 홈 알림(현재: AI 이미지 답변 완료 등) — `link26_notifications.db`.
abstract final class HomeNotificationRepository {
  HomeNotificationRepository._();

  static Database? _db;

  static const _kindAiChatImage = 'ai_chat_image';
  static const _kindSystemSync = 'system_sync';

  /// insert / markRead 후 증가 — 배지·목록 갱신용.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void _bump() => revision.value = revision.value + 1;

  static Future<void> _deleteAllKind(String kind) async {
    final db = await _open();
    await db.delete(
      'home_notifications',
      where: 'kind = ?',
      whereArgs: [kind],
    );
    _bump();
  }

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'link26_notifications.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE home_notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL,
            title TEXT NOT NULL,
            preview TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            read INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_home_notif_kind_read ON home_notifications(kind, read)',
        );
      },
    );
    return _db!;
  }

  static Future<int> insertAiChatImageReply({
    required String title,
    required String preview,
  }) async {
    await _deleteAllKind(_kindAiChatImage);
    final db = await _open();
    var ptext = preview.trim();
    if (ptext.length > 500) ptext = '${ptext.substring(0, 500)}…';
    final id = await db.insert('home_notifications', {
      'kind': _kindAiChatImage,
      'title': title.trim(),
      'preview': ptext,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'read': 0,
    });
    _bump();
    return id;
  }

  /// 홈 부팅 시 예전 「복약 동기화 건너뜀」 알림 제거.
  static Future<void> clearSystemSyncNotices() async {
    await _deleteAllKind(_kindSystemSync);
  }

  static Future<int> insertSystemSyncNotice({
    required String title,
    required String preview,
  }) async {
    await _deleteAllKind(_kindSystemSync);
    final db = await _open();
    var ptext = preview.trim();
    if (ptext.length > 800) ptext = '${ptext.substring(0, 800)}…';
    final id = await db.insert('home_notifications', {
      'kind': _kindSystemSync,
      'title': title.trim(),
      'preview': ptext,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'read': 0,
    });
    _bump();
    return id;
  }

  static Future<List<HomeNotificationRow>> listSystemSync({
    int limit = 80,
  }) async {
    final db = await _open();
    final rows = await db.query(
      'home_notifications',
      where: 'kind = ?',
      whereArgs: [_kindSystemSync],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(HomeNotificationRow.fromMap).toList();
  }

  static Future<int> unreadCountSystemSync() async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as c FROM home_notifications WHERE kind = ? AND read = 0',
      [_kindSystemSync],
    );
    return ((rows.first['c'] as num?)?.toInt()) ?? 0;
  }

  static Future<void> markAllSystemSyncRead() async {
    final db = await _open();
    await db.update(
      'home_notifications',
      {'read': 1},
      where: 'kind = ? AND read = 0',
      whereArgs: [_kindSystemSync],
    );
    _bump();
  }

  static Future<int> unreadCountAiChat() async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as c FROM home_notifications WHERE kind = ? AND read = 0',
      [_kindAiChatImage],
    );
    return ((rows.first['c'] as num?)?.toInt()) ?? 0;
  }

  static Future<List<HomeNotificationRow>> listAiChat({
    int limit = 80,
  }) async {
    final db = await _open();
    final rows = await db.query(
      'home_notifications',
      where: 'kind = ?',
      whereArgs: [_kindAiChatImage],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(HomeNotificationRow.fromMap).toList();
  }

  static Future<HomeNotificationRow?> latestUnreadAiChat() async {
    final db = await _open();
    final rows = await db.query(
      'home_notifications',
      where: 'kind = ? AND read = 0',
      whereArgs: [_kindAiChatImage],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HomeNotificationRow.fromMap(rows.first);
  }

  static Future<void> markRead(int id) async {
    final db = await _open();
    await db.update(
      'home_notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    _bump();
  }

  static Future<void> markAllAiChatRead() async {
    final db = await _open();
    await db.update(
      'home_notifications',
      {'read': 1},
      where: 'kind = ? AND read = 0',
      whereArgs: [_kindAiChatImage],
    );
    _bump();
  }
}

class HomeNotificationRow {
  const HomeNotificationRow({
    required this.id,
    required this.kind,
    required this.title,
    required this.preview,
    required this.createdAtMs,
    required this.read,
  });

  final int id;
  final String kind;
  final String title;
  final String preview;
  final int createdAtMs;
  final bool read;

  factory HomeNotificationRow.fromMap(Map<String, Object?> m) {
    return HomeNotificationRow(
      id: m['id'] as int,
      kind: m['kind'] as String? ?? '',
      title: m['title'] as String? ?? '',
      preview: m['preview'] as String? ?? '',
      createdAtMs: m['created_at'] as int? ?? 0,
      read: (m['read'] as int? ?? 0) != 0,
    );
  }
}
