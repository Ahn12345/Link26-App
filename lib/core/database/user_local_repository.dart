import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 로컬 SQLite — 첫 실행 시 회원 없으면 회원가입 유도. 실서비스는 서버 DB와 동기화 가정.
abstract final class UserLocalRepository {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'link26_users.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            display_name TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  static String _hash(String email, String password) {
    final bytes = utf8.encode('${email.trim().toLowerCase()}|${password.trim()}');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> emailExists(String email) async {
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<bool> hasAnyUser() async {
    final db = await _open();
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM users');
    final c = rows.first['c'] as int? ?? 0;
    return c > 0;
  }

  static Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final db = await _open();
    await db.insert(
      'users',
      {
        'email': email.trim().toLowerCase(),
        'password_hash': _hash(email, password),
        'display_name': displayName,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  static Future<bool> verifyCredentials(String email, String password) async {
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['password_hash'] == _hash(email, password);
  }
}
