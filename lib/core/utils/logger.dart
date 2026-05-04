import 'package:flutter/foundation.dart';

void appLog(String message, {Object? error, StackTrace? stack}) {
  if (kDebugMode) {
    debugPrint('[Link26] $message');
    if (error != null) debugPrint('$error');
    if (stack != null) debugPrint('$stack');
  }
}
