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
/// 앱·BFF 흐름은 간편인증 결과를 CODEF 건보 진료·투약 상품에 넘기는 용도입니다.
/// 운영에서는 BFF에만 키를 두고 [Link26BffIntegrationsClient]로 프록시하는 편이 안전합니다.
/// 앱에서 직접 호출 시 [TilkoEnv] + [TilkoHiraSimpleAuthClient] 생성자를 사용하세요.

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

  Future<String> fetchPublicKey() async {
    if (apiKey.isEmpty) {
      throw StateError('TILKO_API_KEY 가 비어 있습니다.');
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
}
