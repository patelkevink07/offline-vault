import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/crypto/crypto_service.dart';
import 'core/crypto/key_manager.dart';
import 'core/storage/file_storage_service.dart';
import 'core/utils/env_config.dart';
import 'core/utils/logger.dart';
import 'data/remote/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  VaultLogger.i('Starting Offline Vault app...');
  EnvConfig.printConfigStatus();

  // Initialize KeyManager and crypto
  final keyManager = KeyManager();
  final cryptoService = CryptoService(keyManager: keyManager);
  await cryptoService.init();

  // Clean temp files left from past runs
  final storageService = FileStorageService(cryptoService: cryptoService);
  await storageService.cleanTempFiles();

  // Initialize Supabase client
  try {
    await SupabaseService.initialize();
  } catch (e) {
    VaultLogger.w('Supabase initialization failed (offline mode)', e);
  }

  runApp(
    const ProviderScope(
      child: OfflineVaultApp(),
    ),
  );
}
