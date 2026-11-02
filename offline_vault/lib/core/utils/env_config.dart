import 'package:flutter/foundation.dart';

/// Central environment configuration.
/// Values are read from compile-time `--dart-define` with fallbacks.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tdjpjkumjtuvsiabxmbl.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkanBqa3VtanR1dnNpYWJ4bWJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2MTk0MDIsImV4cCI6MjEwOTE5NTQwMn0.18qRlXuj-u71BZWays0JwEoxycanXSFthlP_UaxSh4M',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '208697785706-748hcl816ah24bdb3inkkdf2s9lo56nr.apps.googleusercontent.com',
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
