import 'package:flutter/foundation.dart';

/// Secure logger that never logs sensitive information such as codes, tokens,
/// filenames, or personal user data.
class VaultLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] ${_sanitize(message)}');
    }
  }

  static void i(String message) {
    debugPrint('[INFO] ${_sanitize(message)}');
  }

  static void w(String message, [Object? error]) {
    debugPrint('[WARN] ${_sanitize(message)} ${error != null ? 'Error: $error' : ''}');
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] ${_sanitize(message)} ${error != null ? 'Error: $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static String _sanitize(String input) {
    // Redact 8-character codes or tokens
    final inviteCodeRegex = RegExp(r'\b[A-HJ-NP-Z2-9]{4}-?[A-HJ-NP-Z2-9]{4}\b', caseSensitive: false);
    return input.replaceAll(inviteCodeRegex, '[REDACTED_CODE]');
  }
}
