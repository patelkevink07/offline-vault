import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the lifecycle of the AES-256 master encryption key.
///
/// The key is stored in [FlutterSecureStorage], which uses the
/// Android Keystore on Android and the Keychain on iOS.
class KeyManager {
  KeyManager({FlutterSecureStorage? secureStorage})
      : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// The storage key under which the master key is persisted.
  static const String _masterKeyStorageKey = 'offline_vault_master_key';

  /// Alias for [getOrCreateKey]
  Future<SecretKey> getOrCreateMasterKey() => getOrCreateKey();

  /// Get the existing master key, or generate and store a new one.
  Future<SecretKey> getOrCreateKey() async {
    final existing = await _loadKey();
    if (existing != null) return existing;
    return _generateAndStoreKey();
  }

  /// Check whether a master key has been created.
  Future<bool> hasKey() async {
    final raw = await _storage.read(key: _masterKeyStorageKey);
    return raw != null;
  }

  /// Delete the master key. This makes all encrypted data unrecoverable.
  /// Only call this during a deliberate account wipe.
  Future<void> deleteKey() async {
    await _storage.delete(key: _masterKeyStorageKey);
  }

  /// Export the key bytes for backup purposes. Handle with extreme care.
  Future<Uint8List?> exportKeyBytes() async {
    final raw = await _storage.read(key: _masterKeyStorageKey);
    if (raw == null) return null;
    return base64Decode(raw);
  }

  /// Import a key from raw bytes. Overwrites any existing key.
  Future<void> importKeyBytes(Uint8List keyBytes) async {
    if (keyBytes.length != 32) {
      throw ArgumentError('Key must be exactly 32 bytes (256 bits)');
    }
    final encoded = base64Encode(keyBytes);
    await _storage.write(key: _masterKeyStorageKey, value: encoded);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Future<SecretKey?> _loadKey() async {
    final raw = await _storage.read(key: _masterKeyStorageKey);
    if (raw == null) return null;
    final bytes = base64Decode(raw);
    return SecretKey(bytes);
  }

  Future<SecretKey> _generateAndStoreKey() async {
    final algorithm = AesGcm.with256bits();
    final key = await algorithm.newSecretKey();
    final keyBytes = await key.extractBytes();
    final encoded = base64Encode(keyBytes);
    await _storage.write(key: _masterKeyStorageKey, value: encoded);
    return key;
  }
}

/// Riverpod provider for [KeyManager].
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager();
});
