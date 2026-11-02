import 'package:flutter/foundation.dart';

/// Central environment configuration.
/// Values are read from compile-time `--dart-define` with fallbacks.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://10.0.2.2:54321', // Android emulator default for local Supabase
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjAwMDAwMDAwLCJleHAiOjIwMDAwMDAwMDB9.c2lnbmF0dXJlX2Zvcl9kZXZlbG9wbWVudF90ZXN0aW5nX29ubHk',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('development');

  static void printConfigStatus() {
    if (kDebugMode) {
      debugPrint('[EnvConfig] Supabase URL: $supabaseUrl');
      debugPrint('[EnvConfig] Anon Key configured: ${supabaseAnonKey.isNotEmpty}');
    }
  }
}
