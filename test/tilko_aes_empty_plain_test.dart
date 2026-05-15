import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';

/// [TilkoHiraSimpleAuthClient] logincheck 폴링 시 빈 토큰 필드 처리와 동일한 가드.
String encryptFieldOrEmpty(Uint8List aesKey, String plain) {
  if (plain.isEmpty) return '';
  final key = Key(aesKey);
  final iv = IV.allZerosOfLength(16);
  final enc = Encrypter(AES(key, mode: AESMode.cbc));
  return enc.encrypt(plain, iv: iv).base64;
}

void main() {
  test('empty plain text does not throw (logincheck before tokens)', () {
    final aesKey = Uint8List(16);
    expect(() => encryptFieldOrEmpty(aesKey, ''), returnsNormally);
    expect(encryptFieldOrEmpty(aesKey, ''), '');
  });

  test('non-empty plain text encrypts', () {
    final aesKey = Uint8List(16);
    final out = encryptFieldOrEmpty(aesKey, 'KAKAO');
    expect(out, isNotEmpty);
  });
}
