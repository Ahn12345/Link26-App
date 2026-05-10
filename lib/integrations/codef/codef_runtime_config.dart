import 'package:flutter_dotenv/flutter_dotenv.dart';

/// CODEF(코드에프) 연동용 — `.env` 우선, 없으면 `--dart-define=CODEF_*`.
///
/// 민감 정보는 **가능하면 BFF에서만** 쓰고, 앱 번들에 시크릿을 두는 것은 보안상 지양하세요.
abstract final class CodefRuntimeConfig {
  static String get clientId {
    final v = dotenv.env['CODEF_CLIENT_ID']?.trim() ?? '';
    if (v.isNotEmpty) return v;
    return const String.fromEnvironment('CODEF_CLIENT_ID', defaultValue: '');
  }

  static String get clientSecret {
    final v = dotenv.env['CODEF_CLIENT_SECRET']?.trim() ?? '';
    if (v.isNotEmpty) return v;
    return const String.fromEnvironment('CODEF_CLIENT_SECRET', defaultValue: '');
  }

  /// PEM/한 줄 공개키 문자열 등 CODEF 가이드 형식 그대로.
  static String get publicKey {
    final v = dotenv.env['CODEF_PUBLIC_KEY']?.trim() ?? '';
    if (v.isNotEmpty) return v;
    return const String.fromEnvironment('CODEF_PUBLIC_KEY', defaultValue: '');
  }

  static bool get isConfigured =>
      clientId.isNotEmpty &&
      clientSecret.isNotEmpty &&
      publicKey.isNotEmpty;
}
