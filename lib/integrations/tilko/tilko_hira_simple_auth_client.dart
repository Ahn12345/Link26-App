import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:link26_app/integrations/tilko/tilko_env_resolver.dart';
import 'package:link26_app/integrations/tilko/tilko_rrn_fields.dart';
import 'package:pointycastle/asymmetric/api.dart' show RSAPublicKey;

/// 틸코 **건강보험공단(NHIS) 간편인증** 및 진료·투약 조회.
///
/// - `POST /api/v1.0/nhissimpleauth/simpleauthrequest` — 공단 간편인증 요청
/// - `POST /api/v1.0/nhissimpleauth/retrievetreatmentinjectioninformationperson` — [간편인증용] 진료 및 투약 정보
///
/// (구) 심평원 **내가 먹는 약** `hirasimpleauth/hiraa050300000100` 는 [requestHiraMyMedicationsSimpleAuth] 로
/// 필요 시 그대로 호출할 수 있습니다. BFF 기본 플로우는 NHIS 간편인증 경로를 씁니다.
///
/// 운영에서는 BFF에만 키를 두고 [Link26BffIntegrationsClient]로 프록시하는 편이 안전합니다.

/// NHIS 간편인증 완료 확인 — 틸코 최신 v2 (v1 `logincheck`는 Result=대기만 올 수 있음).
const String kTilkoNhisLoginCheckV2Path =
    '/api/v2.0/NhisSimpleAuth/LoginCheck';

/// PASS `logincheck` 폴링 — 틸코: 승인 후 약 5초 내 Result=true (여유 포함).
const int kTilkoNhisLoginCheckMaxAttempts = 45;
const Duration kTilkoNhisLoginCheckPollInterval =
    Duration(milliseconds: 1500);

/// NHIS `LoginCheck` 경로 — v2 우선, v1은 404·구환경 폴백만.
List<String> tilkoNhisLoginCheckPathCandidates({bool includeHiraV1 = false}) {
  final paths = <String>[kTilkoNhisLoginCheckV2Path];
  paths.add('/api/v1.0/nhissimpleauth/logincheck');
  if (includeHiraV1) {
    paths.add('/api/v1.0/hirasimpleauth/logincheck');
  }
  return paths;
}

/// 앱: `phase=continue` 전 PASS 앱·문자 확인 시간.
const Duration kLink26PassPreContinueDelayNoUri = Duration(seconds: 6);
const Duration kLink26PassPreContinueDelayWithUri = Duration(seconds: 2);

/// BFF `phase=continue` 한 번의 HTTP 상한(폴링 45회×1.5초 + 틸코 HTTP).
const Duration kLink26BffFlowContinueHttpTimeout = Duration(seconds: 180);

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

/// NHIS 간편인증 후 진료·투약 조회에 필요한 4필드가 [root] JSON 안에 모두 있는지.
bool tilkoNhisAuthTokensComplete(dynamic root) {
  for (final k in ['CxId', 'ReqTxId', 'Token', 'TxId']) {
    if ((tilkoFindPlainString(root, k) ?? '').trim().isEmpty) {
      return false;
    }
  }
  return true;
}

/// v2 LoginCheck — `simpleauth`와 달리 응답 본문에 토큰이 없습니다. 토큰 유무로 오류 판정하면 안 됩니다.
bool tilkoNhisLoginCheckIndicatesError(Map<String, dynamic>? root) {
  if (root == null) return false;
  if (tilkoNhisLoginCheckSucceeded(root)) return false;

  final code = (tilkoFindPlainString(root, 'ErrorCode') ?? '').trim();
  if (code.isNotEmpty && code != '0') return true;

  final status = (tilkoFindPlainString(root, 'Status') ?? '').trim().toUpperCase();
  if (status == 'ERROR') return true;

  final msg = (tilkoFindPlainString(root, 'Message') ?? '').trim();
  if (msg.isEmpty) return false;
  if (msg.contains('일시적인 장애') ||
      msg.contains('찾을 수 없') ||
      msg.contains('실패') ||
      msg.contains('오류') ||
      msg.contains('유효하지')) {
    return true;
  }
  return false;
}

/// LoginCheck `Message`만 "성공"인데 `Result`는 아직 false인 경우가 많음 — 실패 문구로 쓰지 않음.
bool tilkoNhisLoginCheckMessageLooksBenign(String msg) {
  final m = msg.trim().toLowerCase();
  if (m.isEmpty) return true;
  const benign = <String>{
    '성공',
    'success',
    'ok',
    '완료',
    '정상',
    '대기',
    '진행',
  };
  return benign.contains(m);
}

/// logincheck 실패 시 사용자·BFF hint용.
String tilkoNhisLoginCheckHintKo(Map<String, dynamic>? root) {
  if (root == null) {
    return '간편인증 완료 확인(logincheck) 응답이 없습니다.';
  }
  if (tilkoNhisLoginCheckSucceeded(root)) {
    return '간편인증은 확인됐지만 복약 조회 단계에서 문제가 있었습니다. BFF 로그를 확인하세요.';
  }
  final msg = (tilkoFindPlainString(root, 'Message') ?? '').trim();
  final status = (tilkoFindPlainString(root, 'Status') ?? '').trim();
  final apiTx = (tilkoFindPlainString(root, 'ApiTxKey') ?? '').trim();
  if (msg.contains('일시적인 장애')) {
    return '틸코 API가 LoginCheck(간편인증 완료 확인)에서 일시 오류를 반환했습니다. '
        '잠시 후 다시 시도하거나 틸코에 ApiTxKey${apiTx.isEmpty ? '' : '($apiTx)'} 로 문의하세요. '
        'PASS 「나의 인증내역」이 「PASS인증서」로만 보이면 통신사 PASS(코드 4)와 다를 수 있습니다.';
  }
  if (tilkoNhisLoginCheckIndicatesError(root)) {
    return msg.isNotEmpty
        ? '틸코 LoginCheck: $msg'
        : '틸코 LoginCheck Status=$status — PASS 승인 후 다시 시도하세요.';
  }
  if (tilkoNhisLoginCheckMessageLooksBenign(msg)) {
    return 'PASS 앱·문자에서 인증을 승인한 뒤, 요청 후 2분 안에 다시 시도하세요. '
        '(LoginCheck는 아직 완료(Result=true)로 확인되지 않았습니다.)';
  }
  if (msg.isNotEmpty) {
    return '틸코 LoginCheck: $msg — PASS 승인 후 다시 시도하세요.';
  }
  return 'PASS 앱·문자에서 인증을 승인한 뒤, 요청 후 2분 안에 다시 시도하세요.';
}

/// [waitForNhisAuthForTreatmentInjection] 반환값의 `_link26_last_logincheck` 본문.
Map<String, dynamic>? tilkoNhisLastLoginCheckBody(Map<String, dynamic> tilkoAuth) {
  final last = tilkoAuth['_link26_last_logincheck'];
  if (last is! Map) return null;
  if (last['body'] is Map<String, dynamic>) {
    return last['body'] as Map<String, dynamic>;
  }
  if (last['body'] is Map) {
    return Map<String, dynamic>.from(
      (last['body'] as Map).map((k, v) => MapEntry('$k', v)),
    );
  }
  return Map<String, dynamic>.from(
    last.map((k, v) => MapEntry('$k', v)),
  );
}

/// simpleauth 토큰 + (폴링 성공 또는 마지막 LoginCheck `Result=true`) — NHIS·HIRA 조회 가능.
bool tilkoNhisSimpleAuthReadyForTreatmentFetch(Map<String, dynamic> tilkoAuth) {
  if (!tilkoNhisAuthTokensComplete(tilkoAuth)) return false;
  final pollErr = tilkoAuth['_link26_poll_error'];
  if (pollErr is! String || pollErr.trim().isEmpty) return true;
  final lc = tilkoNhisLastLoginCheckBody(tilkoAuth);
  return lc != null && tilkoNhisLoginCheckSucceeded(lc);
}

/// NHIS `logincheck` — 휴대폰 간편인증 완료 여부(`Result` boolean). 토큰은 포함하지 않음.
bool tilkoNhisLoginCheckSucceeded(Map<String, dynamic> root) {
  final lifted = tilkoNhisLiftNestedSession(root);
  final v = lifted['Result'] ?? lifted['result'];
  if (v is bool) return v;
  if (v is num) return v == 1;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'y' || s == 'yes';
  }
  return false;
}

/// NHIS `simpleauthrequest` 비즈니스 오류(ErrorCode≠0 또는 Message/Status 실패) 여부.
bool tilkoNhisSimpleAuthIndicatesError(Map<String, dynamic> root) {
  final code = (tilkoFindPlainString(root, 'ErrorCode') ?? '').trim();
  if (code.isNotEmpty && code != '0') return true;

  final status = (tilkoFindPlainString(root, 'Status') ?? '').trim().toUpperCase();
  if (status.isNotEmpty &&
      status != 'OK' &&
      status != 'SUCCESS' &&
      status != 'Y') {
    return true;
  }

  final msg = (tilkoFindPlainString(root, 'Message') ?? '').trim();
  if (msg.isEmpty) return false;
  if (msg.contains('찾을 수 없') ||
      msg.contains('실패') ||
      msg.contains('오류') ||
      msg.contains('유효하지')) {
    return true;
  }

  return !tilkoNhisAuthTokensComplete(tilkoNhisLiftNestedSession(root));
}

/// 틸코 `PrivateAuthType` — 문서·샘플 기본은 채널 이름(예: KAKAO, PASS).
String tilkoPrivateAuthTypeName(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'KAKAO';
  // 틸코 apidemo·운영 회신(2025): 0=카카오 … 4=통신사PASS, 5=신한, 6=네이버
  if (RegExp(r'^\d{1,2}$').hasMatch(t)) {
    switch (t) {
      case '0':
        return 'KAKAO';
      case '1':
        return 'PAYCO';
      case '2':
        return 'KB';
      case '3':
        return 'SAMSUNG';
      case '4':
        return 'PASS';
      case '5':
        return 'SHINHAN';
      case '6':
        return 'NAVER';
      case '7':
        return 'TOSS';
      default:
        return 'KAKAO';
    }
  }
  return t.toUpperCase();
}

/// 일부 환경에서 숫자 코드(1=카카오 …)만 받는 경우 — [tilkoPrivateAuthTypeCandidates] 로 순서 시도.
String tilkoPrivateAuthTypeNumeric(String raw) {
  final name = tilkoPrivateAuthTypeName(raw);
  switch (name) {
    case 'KAKAO':
      return '0';
    case 'PAYCO':
      return '1';
    case 'KB':
    case 'KBMOBILE':
      return '2';
    case 'SAMSUNG':
    case 'SAMSUNGPASS':
      return '3';
    case 'PASS':
    case 'TELCO':
    case 'PHONE':
      return '4';
    case 'SHINHAN':
      return '5';
    case 'NAVER':
      return '6';
    case 'TOSS':
      return '7';
    default:
      return '0';
  }
}

/// NHIS 1회 시도로 충분한 채널(포인트·중복 호출 방지).
bool tilkoIsSingleShotAuthChannel(String raw) {
  final n = tilkoPrivateAuthTypeName(raw);
  return n == 'KAKAO' || n == 'PASS';
}

String tilkoSimpleAuthChannelLabelKo(String raw) {
  switch (tilkoPrivateAuthTypeName(raw)) {
    case 'PASS':
      return '통신사 PASS';
    case 'KAKAO':
      return '카카오';
    case 'NAVER':
      return '네이버';
    case 'TOSS':
      return '토스';
    default:
      return tilkoPrivateAuthTypeName(raw);
  }
}

/// BFF simpleauth — 틸코 운영 API는 숫자 코드(1=카카오)를 먼저 시도한 뒤 채널 이름.
List<String> tilkoPrivateAuthTypeCandidates(String raw) {
  final name = tilkoPrivateAuthTypeName(raw);
  final num = tilkoPrivateAuthTypeNumeric(raw);
  if (num == name) return <String>[name];
  return <String>[num, name];
}

/// 단일 호출 경로 기본값(이름).
String tilkoPrivateAuthTypePlain(String raw) => tilkoPrivateAuthTypeName(raw);

/// 틸코 API AES 필드용 — 숫자 코드는 그대로. NHIS PASS 등은 틸코 숫자 코드(4=통신사PASS).
String tilkoPrivateAuthTypeWirePlain(String raw) {
  final t = raw.trim();
  if (RegExp(r'^\d{1,2}$').hasMatch(t)) return t;
  final name = tilkoPrivateAuthTypeName(raw);
  // 문자열 "PASS" 는 틸코가 거절 — 통신사 PASS 는 `4` (5=신한인증서).
  if (name == 'PASS' ||
      name == 'KAKAO' ||
      name == 'PAYCO' ||
      name == 'KB' ||
      name == 'SAMSUNG' ||
      name == 'SHINHAN' ||
      name == 'NAVER' ||
      name == 'TOSS') {
    return tilkoPrivateAuthTypeNumeric(raw);
  }
  return name;
}

/// BFF 로그용(마스킹) — simpleauthrequest 직전 필드 요약.
String tilkoSimpleAuthRequestLogLine(Map<String, dynamic> m) {
  final birth = '${m['BirthDate'] ?? m['birthDate'] ?? ''}'.trim();
  final phoneRaw =
      '${m['UserCellphoneNumber'] ?? m['userCellphoneNumber'] ?? ''}'.trim();
  final phone = tilkoFormatCellphoneHyphen(phoneRaw);
  final maskedPhone = phone.length >= 4
      ? '***${phone.substring(phone.length - 4)}'
      : '***';
  final pat = tilkoPrivateAuthTypeWirePlain(
    '${m['PrivateAuthType'] ?? m['privateAuthType'] ?? 'KAKAO'}',
  );
  final name = '${m['UserName'] ?? m['userName'] ?? ''}'.trim();
  return 'UserName=$name BirthDate=$birth phone=$maskedPhone '
      'PrivateAuthType(wire)=$pat plain=NHIS';
}

bool tilkoSimpleAuthMessageRetryable(String? message) {
  final m = (message ?? '').trim();
  if (m.isEmpty) return false;
  // 본인 불일치·이력 없음 — 같은 입력으로 재호출해도 결과 동일(포인트만 소모).
  if (m.contains('조회된 데이터가 없습니다')) return false;
  if (m.contains('찾을 수 없')) return false;
  return false;
}

/// NHIS·HIRA simpleauth 실패 시 사용자 안내 — NHIS 오류를 우선합니다.
String tilkoBestSimpleAuthHintKo({
  Map<String, dynamic>? nhisLifted,
  Map<String, dynamic>? hiraLifted,
  String privateAuthType = 'PASS',
}) {
  final label = tilkoSimpleAuthChannelLabelKo(privateAuthType);
  if (nhisLifted != null) {
    final m = (tilkoFindPlainString(nhisLifted, 'Message') ?? '').trim();
    if (m.contains('찾을 수 없')) {
      return tilkoFriendlyHintFromLifted(
        nhisLifted,
        privateAuthType: privateAuthType,
      );
    }
  }
  if (nhisLifted != null && hiraLifted != null) {
    final hiraMsg = (tilkoFindPlainString(hiraLifted, 'Message') ?? '').trim();
    if (hiraMsg.contains('조회된 데이터가 없습니다')) {
      return '건강보험공단(NHIS) $label 간편인증이 되지 않았습니다. '
          '$label 실명·휴대폰·생년월일과 앱 입력(이름·주민번호)이 같은지 확인하세요. '
          '심평원(HIRA)에 처방 이력이 없어도 공단 간편인증은 먼저 성공해야 합니다.';
    }
  }
  if (nhisLifted != null) {
    return tilkoFriendlyHintFromLifted(
      nhisLifted,
      privateAuthType: privateAuthType,
    );
  }
  if (hiraLifted != null) {
    return tilkoFriendlyHintFromLifted(
      hiraLifted,
      privateAuthType: privateAuthType,
    );
  }
  return tilkoSimpleAuthDefaultHintKo(privateAuthType);
}

/// 틸코 NHIS에 넣을 휴대폰 후보 — 하이픈(010-1234-5678) → 숫자만.
List<String> tilkoCellphoneWireCandidates(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final hyphen = tilkoFormatCellphoneHyphen(phone);
  if (digits.isEmpty) return <String>[hyphen];
  if (hyphen == digits) return <String>[digits];
  return <String>[hyphen, digits];
}

String _tilkoValueNotFoundUserKoFor(String channelRaw) {
  final label = tilkoSimpleAuthChannelLabelKo(channelRaw);
  if (tilkoPrivateAuthTypeName(channelRaw) == 'PASS') {
    return '틸코에 PASS 인증을 요청했으나, 통신사 본인정보(실명·휴대폰·생년월일)가 '
        '맞지 않아 문자·PASS 앱 인증창이 열리지 않았습니다. '
        'PASS 앱에서 본인인증을 맞춘 뒤 다시 「연동 시작」을 눌러 주세요.';
  }
  return '앱 DB에는 정보가 있으나, $label 간편인증에 등록된 본인(실명·휴대폰·생년월일)과 '
      '틸코가 맞지 않는다고 응답했습니다. '
      '본인인증 정보를 아래와 같게 맞춘 뒤 다시 시도하세요. '
      '그다음 폰에서 $label 간편인증을 완료해 주세요.';
}

String tilkoNoHiraDataUserKo(String privateAuthType) {
  final label = tilkoSimpleAuthChannelLabelKo(privateAuthType);
  return '심평원(HIRA)에 해당 주민·이름·휴대폰 조합으로 조회된 이력이 없습니다. '
      '입력 정보가 본인·$label 간편인증 등록 정보와 같은지 확인하세요.';
}

String tilkoSimpleAuthDefaultHintKo(String privateAuthType) {
  final label = tilkoSimpleAuthChannelLabelKo(privateAuthType);
  return '이름·생년월일(주민번호)·휴대폰을 $label·틸코에 등록된 정보와 '
      '맞춰 주세요. TILKO_API_KEY에 심평원·NHIS 간편인증(PASS 등) 권한이 있는지 확인하세요.';
}

/// BFF `hint_ko`·앱 스낵바 — 틸코 `Message`/`TargetMessage`의 암호문·원문을 숨깁니다.
String tilkoUserFacingMessageKo(
  String raw, {
  String privateAuthType = 'PASS',
}) {
  final s = raw.trim();
  if (s.isEmpty) return s;
  if (s.contains('찾을 수 없') &&
      (RegExp(r"'[A-Za-z0-9+/=]{4,}'").hasMatch(s) ||
          RegExp(r'[A-Za-z0-9+/=]{12,}={0,2}').hasMatch(s))) {
    return _tilkoValueNotFoundUserKoFor(privateAuthType);
  }
  if (s.contains('조회된 데이터가 없습니다')) {
    return tilkoNoHiraDataUserKo(privateAuthType);
  }
  return raw;
}

String tilkoHintWithApiTxKey(String base, Map<String, dynamic> lifted) {
  final key = (tilkoFindPlainString(lifted, 'ApiTxKey') ?? '').trim();
  if (key.isEmpty) return base;
  return '$base\n(틸코 고객센터 문의 시 ApiTxKey: $key)';
}

/// simpleauthrequest 실패 시 BFF·앱 공통 `hint_ko`.
String tilkoFriendlyHintFromLifted(
  Map<String, dynamic> lifted, {
  String privateAuthType = 'PASS',
}) {
  final target = (tilkoFindPlainString(lifted, 'TargetMessage') ?? '').trim();
  if (target.isNotEmpty && target != '-') {
    final t = tilkoUserFacingMessageKo(
      target,
      privateAuthType: privateAuthType,
    );
    if (t != target || !target.contains('찾을 수 없')) {
      return t;
    }
  }
  final msg = (tilkoFindPlainString(lifted, 'Message') ?? '').trim();
  if (msg.isNotEmpty) {
    return tilkoHintWithApiTxKey(
      tilkoUserFacingMessageKo(msg, privateAuthType: privateAuthType),
      lifted,
    );
  }
  return tilkoHintWithApiTxKey(
    tilkoSimpleAuthDefaultHintKo(privateAuthType),
    lifted,
  );
}

/// 틸코 간편인증 API — 휴대폰 `010-1234-5678` (apidemo·샘플 코드 형식).
String tilkoFormatCellphoneHyphen(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11 && d.startsWith('010')) {
    return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
  }
  if (d.length == 10 && d.startsWith('02')) {
    return '${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}';
  }
  return d;
}

/// 주민등록번호 13자리(숫자만).
String tilkoIdentityDigits13(String raw) => raw.replaceAll(RegExp(r'\D'), '');

/// 틸코·카카오 실명 비교용 — 앞뒤 공백·연속 공백 제거.
String tilkoNormalizeUserName(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s+'), '');

/// 주민번호·생년월일이 함께 올 때 틸코에 넣을 YYYYMMDD — 불일치 시 주민 앞자리 기준.
String? tilkoCoherentBirthYmd({
  String? birthDateYmd,
  String? identityNumber,
}) {
  final birthDigits = (birthDateYmd ?? '').replaceAll(RegExp(r'\D'), '');
  final id = tilkoIdentityDigits13(identityNumber ?? '');
  final fromRrn = id.length == 13 ? TilkoRrnFields.birthYmdFromRrn(id) : null;
  if (fromRrn != null) {
    if (birthDigits.length == 8 && birthDigits != fromRrn) {
      return fromRrn;
    }
    return fromRrn;
  }
  if (birthDigits.length == 8) return birthDigits;
  return null;
}

/// `simpleauthrequest` 직전 — 이름·전화·생년월일·주민번호 정규화·정합.
Map<String, dynamic> tilkoPrepareSimpleAuthRequestMap(Map<String, dynamic> raw) {
  final out = Map<String, dynamic>.from(raw);
  final phone = tilkoFormatCellphoneHyphen(
    '${out['UserCellphoneNumber'] ?? out['userCellphoneNumber'] ?? ''}',
  );
  if (phone.isNotEmpty) {
    out['UserCellphoneNumber'] = phone;
  }
  final name = tilkoNormalizeUserName(
    '${out['UserName'] ?? out['userName'] ?? ''}',
  );
  if (name.isNotEmpty) {
    out['UserName'] = name;
  }
  final id = tilkoIdentityDigits13(
    '${out['IdentityNumber'] ?? out['identityNumber'] ?? ''}',
  );
  if (id.length == 13) {
    out['IdentityNumber'] = id;
  }
  final birthRaw =
      '${out['BirthDate'] ?? out['birthDate'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
  final coherent = tilkoCoherentBirthYmd(
    birthDateYmd: birthRaw,
    identityNumber: id,
  );
  if (coherent != null) {
    out['BirthDate'] = coherent;
  } else if (birthRaw.length == 8) {
    out['BirthDate'] = birthRaw;
  }
  return out;
}

/// logincheck·simpleauth 응답에 토큰 4종이 채워졌는지(값은 출력하지 않음).
String tilkoNhisTokenPresenceSummary(Map<String, dynamic> root) {
  const keys = ['CxId', 'ReqTxId', 'Token', 'TxId'];
  final parts = <String>[];
  for (final k in keys) {
    final v = (tilkoFindPlainString(root, k) ?? '').trim();
    parts.add(v.isEmpty ? '$k=비어있음' : '$k=있음');
  }
  return parts.join(', ');
}

/// 틸코 NHIS 간편인증 응답에서 토큰이 [ResultData]·[Auth] 등 안쪽에만 있을 때 상위와 합쳐 조회에 쓰기 좋게 만듭니다.
Map<String, dynamic> tilkoNhisLiftNestedSession(Map<String, dynamic> m) {
  var out = Map<String, dynamic>.from(m);
  for (final k in <String>[
    'ResultData',
    'resultData',
    'Data',
    'data',
    'Auth',
    'auth',
  ]) {
    final v = out[k];
    if (v is Map<String, dynamic>) {
      out = tilkoMergeJsonMaps(out, v);
    } else if (v is Map) {
      out = tilkoMergeJsonMaps(out, Map<String, dynamic>.from(v));
    } else if (v is String) {
      final t = v.trim();
      if (t.startsWith('{') && t.endsWith('}')) {
        try {
          final parsed = jsonDecode(t);
          if (parsed is Map<String, dynamic>) {
            out = tilkoMergeJsonMaps(out, parsed);
          } else if (parsed is Map) {
            out = tilkoMergeJsonMaps(out, Map<String, dynamic>.from(parsed));
          }
        } catch (_) {}
      }
    }
  }
  return out;
}

Map<String, dynamic> tilkoMergeJsonMaps(
  Map<String, dynamic> base,
  Map<String, dynamic> overlay,
) {
  final out = Map<String, dynamic>.from(base);
  for (final e in overlay.entries) {
    final k = e.key;
    final v = e.value;
    final ex = out[k];
    if (v is Map<String, dynamic> && ex is Map<String, dynamic>) {
      out[k] = tilkoMergeJsonMaps(ex, v);
    } else if (v is Map && ex is Map) {
      out[k] = tilkoMergeJsonMaps(
        Map<String, dynamic>.from(ex),
        Map<String, dynamic>.from(v),
      );
    } else {
      out[k] = v;
    }
  }
  return out;
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

/// Tilko AES-CBC 필드 암호화. 빈·공백만 값은 암호화하지 않습니다(logincheck 초반 토큰).
/// NHIS `simpleauthrequest` JSON 본문 — PrivateAuthType 평문, 나머지 3필드 AES.
Map<String, dynamic> tilkoNhisSimpleAuthRequestBody({
  required Uint8List aesKey,
  required String privateAuthTypePlain,
  required String userName,
  required String birthDateYmd,
  required String userCellphoneHyphen,
}) {
  return <String, dynamic>{
    'PrivateAuthType': privateAuthTypePlain,
    'UserName': tilkoAesEncryptFieldOrEmpty(aesKey, userName),
    'BirthDate': tilkoAesEncryptFieldOrEmpty(aesKey, birthDateYmd),
    'UserCellphoneNumber': tilkoAesEncryptFieldOrEmpty(aesKey, userCellphoneHyphen),
  };
}

/// NHIS v2 `LoginCheck` — `Auth` 객체. AES는 이름·생년월일·휴대폰만(틸코 명세).
Map<String, dynamic> tilkoNhisLoginCheckAuthFields({
  required Uint8List aesKey,
  required String birthDateYmd,
  required String userName,
  required String userCellphoneHyphen,
  required String privateAuthTypePlain,
  required String token,
  required String cxId,
  required String txId,
  required String reqTxId,
}) {
  return <String, dynamic>{
    'BirthDate': tilkoAesEncryptFieldOrEmpty(aesKey, birthDateYmd),
    'UserName': tilkoAesEncryptFieldOrEmpty(aesKey, userName),
    'UserCellphoneNumber':
        tilkoAesEncryptFieldOrEmpty(aesKey, userCellphoneHyphen),
    'PrivateAuthType': privateAuthTypePlain,
    'Token': token,
    'CxId': cxId,
    'TxId': txId,
    'ReqTxId': reqTxId,
  };
}

/// LoginCheck POST 본문 — 래퍼 키 `Auth` (틸코 v2 명세).
List<Map<String, dynamic>> tilkoNhisLoginCheckRequestBodies(
  Map<String, dynamic> authFields,
) {
  return <Map<String, dynamic>>[
    <String, dynamic>{'Auth': authFields},
  ];
}

/// Tilko AES-CBC 필드 암호화 여부(로그·검증).
bool tilkoFieldLooksAesEncrypted(String value) {
  final t = value.trim();
  if (t.isEmpty) return false;
  if (!RegExp(r'^[A-Za-z0-9+/]+=*$').hasMatch(t)) return false;
  return t.length >= 16;
}

String tilkoAesEncryptFieldOrEmpty(Uint8List aesKey, String plain) {
  // encrypt 패키지는 빈 문자열 CBC 암호화 시 RangeError(start: -16) 를 냅니다.
  if (plain.trim().isEmpty) return '';
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
      apiHost: (env['TILKO_API_HOST'] ?? TilkoEnvResolver.demoHost).trim(),
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

    final pat = tilkoPrivateAuthTypeWirePlain(privateAuthType);
    final cell = tilkoFormatCellphoneHyphen(userCellphoneNumber);
    final id = tilkoIdentityDigits13(identityNumber);
    final body = <String, dynamic>{
      'PrivateAuthType': tilkoAesEncryptFieldOrEmpty(aesKey, pat),
      'UserName': tilkoAesEncryptFieldOrEmpty(
        aesKey,
        tilkoNormalizeUserName(userName),
      ),
      'BirthDate': tilkoAesEncryptFieldOrEmpty(aesKey, birthDate.trim()),
      'UserCellphoneNumber': tilkoAesEncryptFieldOrEmpty(aesKey, cell),
      'IdentityNumber': tilkoAesEncryptFieldOrEmpty(aesKey, id),
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

  /// 공단(NHIS) 간편인증 요청 — `POST …/nhissimpleauth/simpleauthrequest`
  /// ([apidemo](https://apidemo.tilko.net/) · 국민건강보험공단 간편인증용).
  ///
  /// BODY 4필드만 — **IdentityNumber 없음** (틸코·apidemo NHIS SimpleAuthRequest).
  /// 암호화: PrivateAuthType 평문, UserName·BirthDate·UserCellphoneNumber AES.
  Future<Map<String, dynamic>> requestNhisSimpleAuth({
    required String privateAuthType,
    required String userName,
    required String birthDate,
    required String userCellphoneNumber,
    String? identityNumber,
    bool includeIdentityNumber = false,
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

    final pat = tilkoPrivateAuthTypeWirePlain(privateAuthType);
    final cell = tilkoFormatCellphoneHyphen(userCellphoneNumber);
    final name = tilkoNormalizeUserName(userName);
    final body = tilkoNhisSimpleAuthRequestBody(
      aesKey: aesKey,
      privateAuthTypePlain: pat,
      userName: name,
      birthDateYmd: birthDate.trim(),
      userCellphoneHyphen: cell,
    );

    final uri = Uri.parse('$_root/api/v1.0/nhissimpleauth/simpleauthrequest');
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
        throw StateError('Tilko NHIS simpleauth HTTP ${res.statusCode}: $text');
      }
      rethrow;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {'http_status': res.statusCode, 'body': decoded};
    }
    return decoded;
  }

  /// 간편인증 **[완료여부 확인]** — NHIS는 v2 [kTilkoNhisLoginCheckV2Path] 우선.
  Future<Map<String, dynamic>> requestTilkoLoginCheck({
    required Map<String, dynamic> tilkoRequestMap,
    required Map<String, dynamic> sessionTokens,
    List<String>? pathCandidates,
  }) async {
    final paths = pathCandidates ?? tilkoNhisLoginCheckPathCandidates();
    if (apiKey.isEmpty) {
      throw StateError('TILKO_API_KEY 가 비어 있습니다.');
    }
    String pickReq(String k) =>
        (tilkoFindPlainString(tilkoRequestMap, k) ?? '').trim();
    String pickTok(String k) =>
        (tilkoFindPlainString(sessionTokens, k) ?? '').trim();

    final userName = pickReq('UserName');
    final birth = pickReq('BirthDate');
    final cell = tilkoFormatCellphoneHyphen(pickReq('UserCellphoneNumber'));
    final pat = tilkoPrivateAuthTypeWirePlain(pickReq('PrivateAuthType'));
    if ([userName, birth, cell, pat].any((e) => e.isEmpty)) {
      throw StateError(
        'Tilko logincheck: 요청맵에 이름·생년월일·휴대폰·인증채널이 필요합니다.',
      );
    }

    final cx = pickTok('CxId');
    final reqTx = pickTok('ReqTxId');
    final token = pickTok('Token');
    final tx = pickTok('TxId');

    final pub = await fetchPublicKey();
    final rnd = Random.secure();
    final aesKey = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      aesKey[i] = rnd.nextInt(256);
    }
    final encKeyHeader = _rsaEncryptAesKeyB64(pub, aesKey);

    final authFields = tilkoNhisLoginCheckAuthFields(
      aesKey: aesKey,
      birthDateYmd: birth,
      userName: userName,
      userCellphoneHyphen: cell,
      privateAuthTypePlain: pat,
      token: token,
      cxId: cx,
      txId: tx,
      reqTxId: reqTx,
    );

    Future<Map<String, dynamic>> postLogin(
      String path,
      Map<String, dynamic> jsonBody,
      String bodyEncKeyHeader,
    ) async {
      final uri = Uri.parse('$_root$path');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'API-KEY': apiKey,
          'ENC-KEY': bodyEncKeyHeader,
        },
        body: jsonEncode(jsonBody),
      );
      final text = res.body;
      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw StateError('Tilko NHIS logincheck HTTP ${res.statusCode}: $text');
        }
        rethrow;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return {'http_status': res.statusCode, 'body': decoded};
      }
      return decoded;
    }

    Map<String, dynamic>? out;
    for (final path in paths) {
      for (final body in tilkoNhisLoginCheckRequestBodies(authFields)) {
        out = await postLogin(path, body, encKeyHeader);
        if (out['http_status'] != 404) break;
      }
      if (out != null && out['http_status'] != 404) break;
    }
    return out ?? <String, dynamic>{'http_status': 404};
  }

  /// NHIS logincheck — v2 LoginCheck 우선.
  Future<Map<String, dynamic>> requestNhisLoginCheck({
    required Map<String, dynamic> tilkoRequestMap,
    required Map<String, dynamic> sessionTokens,
  }) =>
      requestTilkoLoginCheck(
        tilkoRequestMap: tilkoRequestMap,
        sessionTokens: sessionTokens,
        pathCandidates: tilkoNhisLoginCheckPathCandidates(),
      );

  /// `simpleauthrequest`의 ResultData에서 받은 토큰으로 `logincheck`를 폴링해
  /// 휴대폰 간편인증 완료(`Result`==true)까지 기다립니다.
  ///
  /// logincheck 응답에는 토큰이 없습니다(틸코 문서). 토큰이 simpleauth에 없으면 폴링하지 않습니다.
  Future<Map<String, dynamic>> waitForNhisAuthForTreatmentInjection({
    required Map<String, dynamic> tilkoRequestMap,
    required Map<String, dynamic> initialSimpleAuthResponse,
    int maxAttempts = kTilkoNhisLoginCheckMaxAttempts,
    Duration interval = kTilkoNhisLoginCheckPollInterval,
    bool logPollProgress = false,
    List<String>? loginCheckPathCandidates,
  }) async {
    final loginPaths =
        loginCheckPathCandidates ?? tilkoNhisLoginCheckPathCandidates();
    var session = tilkoNhisLiftNestedSession(
      Map<String, dynamic>.from(initialSimpleAuthResponse),
    );

    if (tilkoNhisSimpleAuthIndicatesError(session)) {
      final msg = tilkoFindPlainString(session, 'Message') ?? '';
      final code = tilkoFindPlainString(session, 'ErrorCode') ?? '';
      if (logPollProgress) {
        // ignore: avoid_print
        print(
          'Tilko simpleauth: ErrorCode=$code Message=$msg — '
          '${tilkoNhisTokenPresenceSummary(session)}',
        );
      }
      return {
        ...session,
        '_link26_poll_error': 'simpleauth ErrorCode=$code${msg.isEmpty ? '' : ': $msg'}',
      };
    }

    if (!tilkoNhisAuthTokensComplete(session)) {
      if (logPollProgress) {
        // ignore: avoid_print
        print(
          'Tilko simpleauth: ResultData에 토큰 없음 — logincheck 생략. '
          '${tilkoNhisTokenPresenceSummary(session)} '
          'ErrorCode=${tilkoFindPlainString(session, 'ErrorCode') ?? '-'} '
          'Message=${tilkoFindPlainString(session, 'Message') ?? '-'}',
        );
      }
      return {
        ...session,
        '_link26_poll_error':
            'simpleauthrequest 응답에 CxId·Token 등이 없습니다. '
            'TILKO_API_KEY·상품 권한·.env TILKO_PRIVATE_AUTH_TYPE(예: KAKAO)이 '
            '휴대폰에서 누른 간편인증 앱과 같은지 확인하세요.',
      };
    }

    if (logPollProgress) {
      // ignore: avoid_print
      print(
        'Tilko logincheck: 폴링 시작 (최대 $maxAttempts회, '
        '${interval.inSeconds}초 간격, paths=${loginPaths.join(' → ')}) — '
        '${tilkoNhisTokenPresenceSummary(session)}',
      );
    }

    String? lastPollError;
    Map<String, dynamic>? lastLoginCheck;
    for (var i = 0; i < maxAttempts; i++) {
      Map<String, dynamic> lc;
      try {
        lc = await requestTilkoLoginCheck(
          tilkoRequestMap: tilkoRequestMap,
          sessionTokens: session,
          pathCandidates: loginPaths,
        );
      } catch (e) {
        lastPollError = '$e';
        if (logPollProgress && (i == 0 || (i + 1) % 6 == 0)) {
          // ignore: avoid_print
          print('Tilko logincheck #${i + 1}: 예외 $e');
        }
        await Future<void>.delayed(interval);
        continue;
      }
      lastLoginCheck = lc;
      final lcBody = lc['http_status'] != null
          ? (lc['body'] is Map<String, dynamic>
              ? lc['body'] as Map<String, dynamic>
              : null)
          : lc;
      final loginOk = lcBody != null && tilkoNhisLoginCheckSucceeded(lcBody);
      final lcErr = lcBody != null && tilkoNhisLoginCheckIndicatesError(lcBody);
      if (logPollProgress && ((i + 1) % 6 == 0 || i == 0 || lcErr)) {
        final msg = tilkoFindPlainString(lcBody ?? lc, 'Message') ?? '-';
        final st = tilkoFindPlainString(lcBody ?? lc, 'Status') ?? '-';
        // ignore: avoid_print
        print(
          'Tilko logincheck #${i + 1}: Result=${loginOk ? '완료' : '대기'} '
          'Status=$st Message=$msg '
          '${tilkoNhisTokenPresenceSummary(session)}',
        );
      }
      if (loginOk && tilkoNhisAuthTokensComplete(session)) {
        if (logPollProgress) {
          // ignore: avoid_print
          print('Tilko logincheck: 간편인증 완료 (#${i + 1})');
        }
        return session;
      }
      if (lcErr) {
        lastPollError =
            '틸코 LoginCheck 오류: ${tilkoFindPlainString(lcBody, 'Message') ?? tilkoFindPlainString(lcBody, 'Status') ?? ''}';
        break;
      }
      await Future<void>.delayed(interval);
    }

    final out = Map<String, dynamic>.from(session);
    if (lastLoginCheck != null) {
      out['_link26_last_logincheck'] = lastLoginCheck;
    }
    if (lastPollError != null && lastPollError.trim().isNotEmpty) {
      out['_link26_poll_error'] = lastPollError;
    } else if (lastLoginCheck != null) {
      final lcBody = lastLoginCheck['http_status'] != null
          ? (lastLoginCheck['body'] is Map<String, dynamic>
              ? lastLoginCheck['body'] as Map<String, dynamic>
              : null)
          : lastLoginCheck;
      out['_link26_poll_error'] = tilkoNhisLoginCheckHintKo(
        lcBody is Map<String, dynamic> ? lcBody : null,
      );
    } else {
      out['_link26_poll_error'] =
          'logincheck에서 간편인증 완료(Result=true)를 받지 못했습니다. '
          '휴대폰에서 PASS 앱 또는 문자 인증번호로 간편인증을 완료한 뒤 다시 시도하세요.';
    }
    return out;
  }

  Future<Map<String, dynamic>> requestNhisSimpleAuthFromJsonMap(
    Map<String, dynamic> m, {
    bool includeIdentityNumber = false,
  }) {
    final phone =
        '${m['UserCellphoneNumber'] ?? m['userCellphoneNumber'] ?? ''}'.trim();
    return requestNhisSimpleAuth(
      privateAuthType: '${m['PrivateAuthType'] ?? m['privateAuthType'] ?? ''}',
      userName: '${m['UserName'] ?? m['userName'] ?? ''}',
      birthDate: '${m['BirthDate'] ?? m['birthDate'] ?? ''}',
      userCellphoneNumber: phone,
      identityNumber: '${m['IdentityNumber'] ?? m['identityNumber'] ?? ''}',
      includeIdentityNumber: includeIdentityNumber,
    );
  }

  Future<Map<String, dynamic>> requestFromJsonMap(Map<String, dynamic> m) {
    return requestSimpleAuth(
      privateAuthType:
          '${m['PrivateAuthType'] ?? m['privateAuthType'] ?? ''}'.trim(),
      userName: '${m['UserName'] ?? m['userName'] ?? ''}'.trim(),
      birthDate: '${m['BirthDate'] ?? m['birthDate'] ?? ''}'.trim(),
      userCellphoneNumber: tilkoFormatCellphoneHyphen(
        '${m['UserCellphoneNumber'] ?? m['userCellphoneNumber'] ?? ''}',
      ),
      identityNumber: tilkoIdentityDigits13(
        '${m['IdentityNumber'] ?? m['identityNumber'] ?? ''}',
      ),
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
    final cell = tilkoFormatCellphoneHyphen(pickReq('UserCellphoneNumber'));
    final pat = tilkoPrivateAuthTypeWirePlain(pickReq('PrivateAuthType'));

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
      'IdentityNumber': tilkoAesEncryptFieldOrEmpty(aesKey, identity),
      'StartDate': tilkoAesEncryptFieldOrEmpty(aesKey, startDateYyyymmdd),
      'EndDate': tilkoAesEncryptFieldOrEmpty(aesKey, endDateYyyymmdd),
      'CxId': tilkoAesEncryptFieldOrEmpty(aesKey, cx),
      'PrivateAuthType': tilkoAesEncryptFieldOrEmpty(aesKey, pat),
      'ReqTxId': tilkoAesEncryptFieldOrEmpty(aesKey, reqTx),
      'Token': tilkoAesEncryptFieldOrEmpty(aesKey, token),
      'TxId': tilkoAesEncryptFieldOrEmpty(aesKey, tx),
      'UserName': tilkoAesEncryptFieldOrEmpty(aesKey, userName),
      'BirthDate': tilkoAesEncryptFieldOrEmpty(aesKey, birth),
      'UserCellphoneNumber': tilkoAesEncryptFieldOrEmpty(aesKey, cell),
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

  /// 건강보험공단 간편인증 **[진료 및 투약 정보]** —
  /// `POST …/nhissimpleauth/retrievetreatmentinjectioninformationperson`
  /// ([apidemo](https://apidemo.tilko.net/) 문서 BODY 기준 — IdentityNumber 미포함).
  ///
  /// [tilkoAuthResponse]: [requestNhisSimpleAuth] / [requestNhisSimpleAuthFromJsonMap] 의 JSON.
  Future<Map<String, dynamic>> requestNhisRetrieveTreatmentInjectionInformationPerson({
    required Map<String, dynamic> tilkoRequestMap,
    required Map<String, dynamic> tilkoAuthResponse,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('TILKO_API_KEY 가 비어 있습니다.');
    }
    final liftedAuth = tilkoNhisLiftNestedSession(
      Map<String, dynamic>.from(tilkoAuthResponse),
    );
    String pickReq(String k) =>
        (tilkoFindPlainString(tilkoRequestMap, k) ?? '').trim();

    final userName = pickReq('UserName');
    final birth = pickReq('BirthDate');
    final cell = tilkoFormatCellphoneHyphen(pickReq('UserCellphoneNumber'));
    final pat = tilkoPrivateAuthTypeWirePlain(pickReq('PrivateAuthType'));

    String pickAuth(String k) =>
        (tilkoFindPlainString(liftedAuth, k) ?? '').trim();

    final cx = pickAuth('CxId');
    final reqTx = pickAuth('ReqTxId');
    final token = pickAuth('Token');
    final tx = pickAuth('TxId');

    if ([userName, birth, cell, pat, cx, reqTx, token, tx].any((e) => e.isEmpty)) {
      throw StateError(
        'NHIS RetrieveTreatmentInjectionInformationPerson: 필수 값 누락 — '
        '요청맵(이름·생년월일·휴대폰·인증채널) 또는 간편인증 응답의 '
        'CxId·ReqTxId·Token·TxId 를 찾지 못했습니다.',
      );
    }

    final pub = await fetchPublicKey();
    final rnd = Random.secure();
    final aesKey = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      aesKey[i] = rnd.nextInt(256);
    }
    final encKeyHeader = _rsaEncryptAesKeyB64(pub, aesKey);

    final body = <String, dynamic>{
      'CxId': tilkoAesEncryptFieldOrEmpty(aesKey, cx),
      'PrivateAuthType': tilkoAesEncryptFieldOrEmpty(aesKey, pat),
      'ReqTxId': tilkoAesEncryptFieldOrEmpty(aesKey, reqTx),
      'Token': tilkoAesEncryptFieldOrEmpty(aesKey, token),
      'TxId': tilkoAesEncryptFieldOrEmpty(aesKey, tx),
      'UserName': tilkoAesEncryptFieldOrEmpty(aesKey, userName),
      'BirthDate': tilkoAesEncryptFieldOrEmpty(aesKey, birth),
      'UserCellphoneNumber': tilkoAesEncryptFieldOrEmpty(aesKey, cell),
    };

    final uri = Uri.parse(
      '$_root/api/v1.0/nhissimpleauth/retrievetreatmentinjectioninformationperson',
    );
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
        throw StateError(
          'Tilko NHIS RetrieveTreatmentInjectionInformationPerson HTTP '
          '${res.statusCode}: $text',
        );
      }
      rethrow;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {'http_status': res.statusCode, 'body': decoded};
    }
    return decoded;
  }
}
