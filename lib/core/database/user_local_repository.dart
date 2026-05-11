import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 로컬 SQLite `users` 행 — 로그인 세션·NHIS 연동용.
class LocalUserRecord {
  const LocalUserRecord({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phoneDigits,
    required this.gender,
    required this.residentRegistrationHash,
    required this.privacyConsent,
    this.codefConnectedId,
  });

  final int id;
  final String email;
  final String displayName;
  final String phoneDigits;
  final String gender;
  final String? residentRegistrationHash;
  final bool privacyConsent;

  /// CODEF 기관 연동 후 발급되는 connectedId — BFF 복약 실연동 시 쿼리로 전달.
  final String? codefConnectedId;
}

/// 로컬 SQLite — 첫 실행 시 회원 없으면 회원가입 유도. 실서비스는 서버 DB와 동기화 가정.
abstract final class UserLocalRepository {
  static Database? _db;

  /// 로그인·가입 시 동일 규칙으로 비교·저장 (공백·연속 공백 정리).
  static String normalizeDisplayName(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  static int _intFromSql(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'link26_users.db');
    _db = await openDatabase(
      dbPath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            display_name TEXT,
            phone TEXT,
            gender TEXT,
            resident_registration_hash TEXT,
            privacy_consent INTEGER NOT NULL DEFAULT 0,
            nhis_sync_ok INTEGER,
            nhis_sync_error TEXT,
            nhis_synced_at INTEGER,
            codef_connected_id TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN gender TEXT');
          await db.execute(
              'ALTER TABLE users ADD COLUMN resident_registration_hash TEXT');
          await db.execute(
            'ALTER TABLE users ADD COLUMN privacy_consent INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE users ADD COLUMN nhis_sync_ok INTEGER');
          await db.execute(
              'ALTER TABLE users ADD COLUMN nhis_sync_error TEXT');
          await db.execute(
              'ALTER TABLE users ADD COLUMN nhis_synced_at INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN codef_connected_id TEXT',
          );
        }
      },
    );
    return _db!;
  }

  static String _hash(String email, String password) {
    final bytes =
        utf8.encode('${email.trim().toLowerCase()}|${password.trim()}');
    return sha256.convert(bytes).toString();
  }

  static String _syntheticEmailFromPhone(String phoneDigits) =>
      '$phoneDigits@link26.local';

  /// 이메일·비밀번호 없이 가입할 때 `password_hash` 자리용(평문 비밀번호 없음).
  static String _phoneOnlyPasswordHash(String phoneDigits) => sha256
      .convert(utf8.encode('link26_phone_only|$phoneDigits'))
      .toString();

  /// 주민등록번호는 평문 저장하지 않고 해시만 보관합니다.
  static String _hashResidentRegistration(String thirteenDigitDigitsOnly) {
    return sha256
        .convert(utf8.encode(thirteenDigitDigitsOnly.trim()))
        .toString();
  }

  /// NHIS·BFF 전송용 (DB [resident_registration_hash] 와 동일 알고리즘).
  static String residentRegistrationSha256(String thirteenDigitDigitsOnly) =>
      _hashResidentRegistration(thirteenDigitDigitsOnly);

  /// CODEF 건강·공단 API용 `connectedId` — 비우면 NULL 로 저장합니다.
  static Future<void> updateCodefConnectedId(
    String phoneDigits, {
    required String? connectedId,
  }) async {
    final p = phoneDigits.replaceAll(RegExp(r'\D'), '');
    if (p.length < 10) return;
    final db = await _open();
    final v = connectedId?.trim();
    await db.update(
      'users',
      {
        'codef_connected_id':
            (v == null || v.isEmpty) ? null : v,
      },
      where: 'phone = ?',
      whereArgs: [p],
    );
  }

  static Future<void> updateNhisSyncStatus(
    String phoneDigits, {
    required bool ok,
    String? errorMessage,
  }) async {
    final db = await _open();
    await db.update(
      'users',
      {
        'nhis_sync_ok': ok ? 1 : 0,
        'nhis_sync_error': errorMessage,
        'nhis_synced_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'phone = ?',
      whereArgs: [phoneDigits],
    );
  }

  /// NHIS 필수 연동 실패 시 로컬 가입 롤백.
  static Future<void> deleteUserByPhone(String phoneDigits) async {
    final db = await _open();
    await db.delete(
      'users',
      where: 'phone = ?',
      whereArgs: [phoneDigits],
    );
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

  static Future<bool> phoneExists(String phone) async {
    final p = phone.replaceAll(RegExp(r'\D'), '');
    if (p.isEmpty) return false;
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [p],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<bool> hasAnyUser() async {
    final db = await _open();
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM users');
    if (rows.isEmpty) return false;
    final c = _intFromSql(rows.first['c']);
    return c > 0;
  }

  /// 로컬 `users`가 정확히 한 명일 때만 전화번호(숫자만)를 반환합니다.
  /// [AuthSession.activePhoneDigits]가 비어 있을 때 BFF 복약 동기화 폴백용.
  static Future<String?> singleUserPhoneDigits() async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT phone FROM users WHERE phone IS NOT NULL AND TRIM(phone) != ? '
      'LIMIT 2',
      [''],
    );
    if (rows.length != 1) return null;
    final raw = rows.first['phone'];
    if (raw == null) return null;
    final p = '$raw'.replaceAll(RegExp(r'\D'), '');
    return p.isEmpty ? null : p;
  }

  static Future<void> register({
    required String displayName,
    required String phone,
    required String gender,
    required String residentRegistrationDigits13,
    required bool privacyConsent,
  }) async {
    final p = phone.replaceAll(RegExp(r'\D'), '');
    final email = _syntheticEmailFromPhone(p);
    final db = await _open();
    await db.insert(
      'users',
      {
        'email': email,
        'password_hash': _phoneOnlyPasswordHash(p),
        'display_name': normalizeDisplayName(displayName),
        'phone': p,
        'gender': gender,
        'resident_registration_hash':
            _hashResidentRegistration(residentRegistrationDigits13),
        'privacy_consent': privacyConsent ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  static LocalUserRecord? _mapRowToUser(Map<String, Object?> row) {
    try {
      final id = _intFromSql(row['id']);
      if (id <= 0) return null;
      final email = '${row['email'] ?? ''}';
      final displayName = normalizeDisplayName(
        '${row['display_name'] ?? ''}',
      );
      final phone = row['phone'] as String?;
      final gender = (row['gender'] as String?)?.trim() ?? '';
      final rrn = row['resident_registration_hash'] as String?;
      final privacy = _intFromSql(row['privacy_consent']) == 1;
      final codefId = (row['codef_connected_id'] as String?)?.trim();
      if (phone == null || phone.isEmpty) return null;
      return LocalUserRecord(
        id: id,
        email: email,
        displayName: displayName,
        phoneDigits: phone,
        gender: gender,
        residentRegistrationHash: rrn,
        privacyConsent: privacy,
        codefConnectedId:
            (codefId == null || codefId.isEmpty) ? null : codefId,
      );
    } catch (_) {
      return null;
    }
  }

  /// 표시 이름과 전화번호가 같은 행에 일치할 때만 사용자를 반환합니다.
  static Future<LocalUserRecord?> findUserByNameAndPhone({
    required String displayName,
    required String phone,
  }) async {
    final p = phone.replaceAll(RegExp(r'\D'), '');
    if (p.length < 10) return null;
    final name = normalizeDisplayName(displayName);
    if (name.isEmpty) return null;
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [p],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final user = _mapRowToUser(rows.first);
    if (user == null) return null;
    if (user.displayName != name) return null;
    return user;
  }

  /// 전화번호로 로컬 사용자 한 명 조회(이름 검증 없음).
  static Future<LocalUserRecord?> findUserByPhone(String phone) async {
    final p = phone.replaceAll(RegExp(r'\D'), '');
    if (p.length < 10) return null;
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [p],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapRowToUser(rows.first);
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

  /// 서버 로그인 성공 후 로컬에도 같은 자격증명을 맞춰 두면 다음부터 오프라인 검증이 됩니다.
  static Future<void> upsertCredentials({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final db = await _open();
    final e = email.trim().toLowerCase();
    final hash = _hash(email, password);
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [e],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert(
        'users',
        {
          'email': e,
          'password_hash': hash,
          'display_name': displayName,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } else {
      await db.update(
        'users',
        {
          'password_hash': hash,
          if (displayName != null && displayName.isNotEmpty)
            'display_name': displayName,
        },
        where: 'email = ?',
        whereArgs: [e],
      );
    }
  }
}
