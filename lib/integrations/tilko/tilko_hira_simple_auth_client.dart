import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart' show RSAPublicKey;

/// 틸코 건강보험심사평가원 간편인증 (`/api/v1.0/hirasimpleauth/simpleauthrequest`).
///
/// 틸코 문서의 `Nhis/RetrieveTreatmentInjectionInformationPerson`(apidemo URL의 v2.0 표기와 별개로
/// 본문 경로는 보통 `/api/v1.0/Nhis/...`)는 **공동인증서** 기반이라 이 클라이언트와 다릅니다.
/// 간편인증 후 [requestHiraMyMedicationsSimpleAuth] 로 심평원 **내가 먹는 약**(`hiraa050300000100`)을
/// 호출하는 흐름을 씁니다.
/// 운영에서는 BFF에만 키를 두고 [Link26BffIntegrationsClient]로 프록시하는 편이 안전합니다.
/// 앱에서 직접 호출 시 [TilkoEnv] + [TilkoHiraSimpleAuthClient] 생성자를 사용하세요.

/// 틸코 JSON(중첩·리스트)에서 키 [want]와 대소문자만 다른 첫 문자열 값을 찾습니다.
String? tilkoFindPlainString(dynamic root, String want) {
  final key = want.toLowerCase();
  String? hit;

  void walk(dynamic node) {
    if (hit != null) return;
    if (node is Map) {
      for (final e in node.entries) {
        if ('${e.key}'.toLowerCase() == key) {
          final s = '${e.value}'.trim();
          if (s.isNotEmpty && s != 'null') {
            hit = s;
            return;
          }
        }
      }
      for (final e in node.entries) {
        walk(e.value);
        if (hit != null) return;
      }
    } else if (node is List) {
      for (final e in node) {
        walk(e);
        if (hit != null) return;
      }
    }
  }

  walk(root);
  return hit;
}

/// RSA 공개키(Base64 DER) → PEM 래핑 ([RSAKeyParser]용).
String tilkoPublicKeyToPem(String tilkoPublicKeyB64) {
  final cleaned = tilkoPublicKeyB64.replaceAll(RegExp(r'\s+'), '');
  final buf = StringBuffer('-----BEGIN PUBLIC KEY-----\n');
  for (var i = 0; i < cleaned.length; i += 64) {
    final end = min(i + 64, cleaned.length);
    buf.writeln(cleaned.substring(i, end));
  }
  buf.write('-----END PUBLIC KEY-----');
  return buf.toString();
}

String _aesEncryptField(Uint8List aesKey, String plain) {
  final key = Key(aesKey);
  final iv = IV.allZerosOfLength(16);
  final enc = Encrypter(AES(key, mode: AESMode.cbc));
  final encrypted = enc.encrypt(plain, iv: iv);
  return encrypted.base64;
}

String _rsaEncryptAesKeyB64(String tilkoPublicKeyB64, Uint8List aesKey) {
  final parser = RSAKeyParser();
  final pub = parser.parse(tilkoPublicKeyToPem(tilkoPublicKeyB64)) as RSAPublicKey;
  final rsa = Encrypter(RSA(publicKey: pub, encoding: RSAEncoding.PKCS1));
  final enc = rsa.encryptBytes(aesKey);
  return enc.base64;
}

/// Tilko `GetPublicKey` 는 호출마다 지연이 크므로 짧게 재사용합니다(BFF가 연속 두 API를 부를 때 체감 속도 개선).
class _TilkoPkCacheEntry {
  _TilkoPkCacheEntry(this.pk, this.at);
  final String pk;
  final DateTime at;
}

final Map<String, _TilkoPkCacheEntry> _tilkoPublicKeyCache = {};
const Duration _tilkoPublicKeyTtl = Duration(minutes: 5);

class TilkoHiraSimpleAuthClient {
  TilkoHiraSimpleAuthClient({
    required this.apiKey,
    required this.apiHost,
  });

  factory TilkoHiraSimpleAuthClient.fromBffEnv(Map<String, String> env) {
    return TilkoHiraSimpleAuthClient(
      apiKey: (env['TILKO_API_KEY'] ?? '').trim(),
      apiHost: (env['TILKO_API_HOST'] ?? 'https://dev.tilko.net').trim(),
    );
  }

  final String apiKey;
  final String apiHost;

  String get _root => apiHost.endsWith('/') ? apiHost.substring(0, apiHost.length - 1) : apiHost;

  String _publicKeyCacheKey() => '$_root\u0001$apiKey';

  Future<String> fetchPublicKey() async {
    if (apiKey.isEmpty) {
      throw StateError('TILKO_API_KEY 가 비어 있습니다.');
    }
    final key = _publicKeyCacheKey();
    final now = DateTime.now();
    final cached = _tilkoPublicKeyCache[key];
    if (cached != null && now.difference(cached.at) < _tilkoPublicKeyTtl) {
      return cached.pk;
    }
    final uri = Uri.parse('$_root/api/Auth/GetPublicKey').replace(
      queryParameters: {'APIkey': apiKey},
    );
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Tilko GetPublicKey HTTP ${res.statusCode}: ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final pk = map['PublicKey'] as String?;
    if (pk == null || pk.isEmpty) {
      throw StateError('Tilko 응답에 PublicKey 없음');
    }
    _tilkoPublicKeyCache[key] = _TilkoPkCacheEntry(pk, now);
    return pk;
  }

  /// 필드: PrivateAuthType, UserName, BirthDate(YYYYMMDD), UserCellphoneNumber, IdentityNumber
  Future<Map<String, dynamic>> requestSimpleAuth({
    required String privateAuthType,
    required String userName,
    required String birthDate,
    required String userCellphoneNumber,
    required String identityNumber,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('TILKO_API_KEY 가 비어 있습니다.');
    }
    final pub = await fetchPublicKey();
    final rnd = Random.secure();
    final aesKey = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      aesKey[i] = rnd.nextInt(256);
    }
    final encKeyHeader = _rsaEncryptAesKeyB64(pub, aesKey);

    final body = <String, dynamic>{
      'PrivateAuthType': _aesEncryptField(aesKey, privateAuthType),
      'UserName': _aesEncryptField(aesKey, userName),
      'BirthDate': _aesEncryptField(aesKey, birthDate),
      'UserCellphoneNumber': _aesEncryptField(aesKey, userCellphoneNumber),
      'IdentityNumber': _aesEncryptField(aesKey, identityNumber),
    };

    final uri = Uri.parse('$_root/api/v1.0/hirasimpleauth/simpleauthrequest');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'API-KEY': apiKey,
        'ENC-KEY': encKeyHeader,
      },
      body: jsonEncode(body),
    );

    final text = res.body;
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw StateError('Tilko HTTP ${res.statusCode}: $text');
      }
      rethrow;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {'http_status': res.statusCode, 'body': decoded};
    }
    return decoded;
  }

  Future<Map<String, dynamic>> requestFromJsonMap(Map<String, dynamic> m) {
    return requestSimpleAuth(
      privateAuthType: '${m['PrivateAuthType'] ?? m['privateAuthType'] ?? ''}',
      userName: '${m['UserName'] ?? m['userName'] ?? ''}',
      birthDate: '${m['BirthDate'] ?? m['birthDate'] ?? ''}',
      userCellphoneNumber:
          '${m['UserCellphoneNumber'] ?? m['userCellphoneNumber'] ?? ''}',
      identityNumber: '${m['IdentityNumber'] ?? m['identityNumber'] ?? ''}',
    );
  }

  /// 심평원 간편인증 **[내가 먹는 약]** — `POST …/hirasimpleauth/hiraa050300000100`
  /// (데모: `https://dev.tilko.net/...`, 운영: `https://api.tilko.net/...`).
  ///
  /// [tilkoAuthResponse]: [requestSimpleAuth] / [requestFromJsonMap] 의 JSON.
  /// 문서 필드 CxId·ReqTxId·Token·TxId 등은 응답 전체에서 대소문자 무시로 탐색합니다.
  Future<Map<String, dynamic>> requestHiraMyMedicationsSimpleAuth({
    required Map<String, dynamic> tilkoRequestMap,
    required Map<String, dynamic> tilkoAuthResponse,
    required String startDateYyyymmdd,
    required String endDateYyyymmdd,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('TILKO_API_KEY 가 비어 있습니다.');
    }
    String pickReq(String k) =>
        (tilkoFindPlainString(tilkoRequestMap, k) ?? '').trim();

    final identity = pickReq('IdentityNumber');
    final userName = pickReq('UserName');
    final birth = pickReq('BirthDate');
    final cell = pickReq('UserCellphoneNumber');
    final pat = pickReq('PrivateAuthType');

    String pickAuth(String k) =>
        (tilkoFindPlainString(tilkoAuthResponse, k) ?? '').trim();

    final cx = pickAuth('CxId');
    final reqTx = pickAuth('ReqTxId');
    final token = pickAuth('Token');
    final tx = pickAuth('TxId');

    if ([identity, userName, birth, cell, pat, cx, reqTx, token, tx]
        .any((e) => e.isEmpty)) {
      throw StateError(
        'HIRAA050300000100: 필수 값 누락 — 요청맵(주민·이름·생년월일·휴대폰·인증채널) 또는 '
        '간편인증 응답의 CxId·ReqTxId·Token·TxId 를 찾지 못했습니다.',
      );
    }
    if (!RegExp(r'^\d{8}$').hasMatch(startDateYyyymmdd) ||
        !RegExp(r'^\d{8}$').hasMatch(endDateYyyymmdd)) {
      throw StateError('StartDate/EndDate 는 YYYYMMDD 8자리여야 합니다.');
    }

    final pub = await fetchPublicKey();
    final rnd = Random.secure();
    final aesKey = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      aesKey[i] = rnd.nextInt(256);
    }
    final encKeyHeader = _rsaEncryptAesKeyB64(pub, aesKey);

    final body = <String, dynamic>{
      'IdentityNumber': _aesEncryptField(aesKey, identity),
      'StartDate': _aesEncryptField(aesKey, startDateYyyymmdd),
      'EndDate': _aesEncryptField(aesKey, endDateYyyymmdd),
      'CxId': _aesEncryptField(aesKey, cx),
      'PrivateAuthType': _aesEncryptField(aesKey, pat),
      'ReqTxId': _aesEncryptField(aesKey, reqTx),
      'Token': _aesEncryptField(aesKey, token),
      'TxId': _aesEncryptField(aesKey, tx),
      'UserName': _aesEncryptField(aesKey, userName),
      'BirthDate': _aesEncryptField(aesKey, birth),
      'UserCellphoneNumber': _aesEncryptField(aesKey, cell),
    };

    final uri = Uri.parse('$_root/api/v1.0/hirasimpleauth/hiraa050300000100');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'API-KEY': apiKey,
        'ENC-KEY': encKeyHeader,
      },
      body: jsonEncode(body),
    );

    final text = res.body;
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw StateError('Tilko HIRAA050300000100 HTTP ${res.statusCode}: $text');
      }
      rethrow;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {'http_status': res.statusCode, 'body': decoded};
    }
    return decoded;
  }
}
