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

  // Initialize KeyManager and crypto safely
  final keyManager = KeyManager();
  final cryptoService = CryptoService(keyManager: keyManager);
  try {
    await cryptoService.init();
  } catch (e) {
    VaultLogger.w('CryptoService init warning', e);
  }

  // Clean temp files left from past runs safely
  try {
    final storageService = FileStorageService(cryptoService: cryptoService);
    await storageService.cleanTempFiles();
  } catch (e) {
    VaultLogger.w('Storage clean temp warning', e);
  }

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
