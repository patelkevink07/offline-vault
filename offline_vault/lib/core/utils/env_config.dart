import 'package:flutter/foundation.dart';

/// Central environment configuration.
/// Values MUST be provided via compile-time `--dart-define`.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Validates environment configuration.
  /// Throws a [StateError] at runtime if any required --dart-define is missing.
  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (googleWebClientId.isEmpty) missing.add('GOOGLE_WEB_CLIENT_ID');

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required build configuration. Please pass the following via --dart-define:\n'
        '${missing.map((k) => '  --dart-define=$k=<value>').join('\n')}',
      );
    }
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void printConfigStatus() {
    if (kDebugMode) {
      debugPrint('[EnvConfig] Supabase URL configured: ${supabaseUrl.isNotEmpty}');
      debugPrint('[EnvConfig] Anon Key configured: ${supabaseAnonKey.isNotEmpty}');
      debugPrint('[EnvConfig] Google Web Client ID configured: ${googleWebClientId.isNotEmpty}');
    }
  }
}
