import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/env_config.dart';
import '../../core/utils/logger.dart';

/// Global Supabase client provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    // If Supabase.initialize() was not called or failed (e.g. offline or test environment)
    return SupabaseClient(
      EnvConfig.supabaseUrl,
      EnvConfig.supabaseAnonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: false,
      ),
    );
  }
});

class SupabaseService {
  static Future<void> initialize() async {
    VaultLogger.i('Initializing Supabase client...');
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    VaultLogger.i('Supabase initialized successfully.');
  }
}
