import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure preferences wrapper around [FlutterSecureStorage].
class SecurePrefs {
  SecurePrefs({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;

  static const String _keyPinHash = 'vault_pin_hash';
  static const String _keyPinSalt = 'vault_pin_salt';
  static const String _keyPinIterations = 'vault_pin_iterations';
  static const String _keyFailedPinAttempts = 'vault_pin_failed_attempts';
  static const String _keyPinLockoutUntil = 'vault_pin_locked_until';
  static const String _keyBiometricsEnabled = 'vault_biometrics_enabled';
  static const String _keySyncOnWifiOnly = 'vault_sync_wifi_only';
  static const String _keyBlockScreenshots = 'vault_block_screenshots';
  static const String _keyLanguageCode = 'vault_language_code';

  Future<void> writeString(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> deleteKey(String key) => _storage.delete(key: key);

  Future<void> setPinHash({
    required String hash,
    required String salt,
    int iterations = 100000,
  }) async {
    await writeString(_keyPinHash, hash);
    await writeString(_keyPinSalt, salt);
    await writeString(_keyPinIterations, iterations.toString());
  }

  Future<({String? hash, String? salt, int iterations})> getPinHashAndSalt() async {
    final hash = await readString(_keyPinHash);
    final salt = await readString(_keyPinSalt);
    final iterStr = await readString(_keyPinIterations);
    final iterations = int.tryParse(iterStr ?? '') ?? 100000;
    return (hash: hash, salt: salt, iterations: iterations);
  }

  Future<int> getFailedPinAttempts() async {
    final raw = await readString(_keyFailedPinAttempts);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  Future<void> setFailedPinAttempts(int attempts) =>
      writeString(_keyFailedPinAttempts, attempts.toString());

  Future<DateTime?> getPinLockoutUntil() async {
    final raw = await readString(_keyPinLockoutUntil);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setPinLockoutUntil(DateTime? until) async {
    if (until == null) {
      await deleteKey(_keyPinLockoutUntil);
    } else {
      await writeString(_keyPinLockoutUntil, until.toIso8601String());
    }
  }

  Future<void> clearPin() async {
    await deleteKey(_keyPinHash);
    await deleteKey(_keyPinSalt);
    await deleteKey(_keyPinIterations);
    await deleteKey(_keyFailedPinAttempts);
    await deleteKey(_keyPinLockoutUntil);
  }

  Future<bool> hasPin() async {
    final hash = await readString(_keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setBiometricsEnabled(bool enabled) =>
      writeString(_keyBiometricsEnabled, enabled.toString());

  Future<bool> getBiometricsEnabled() async {
    final value = await readString(_keyBiometricsEnabled);
    return value == 'true';
  }

  Future<void> setSyncOnWifiOnly(bool wifiOnly) =>
      writeString(_keySyncOnWifiOnly, wifiOnly.toString());

  Future<bool> getSyncOnWifiOnly() async {
    final value = await readString(_keySyncOnWifiOnly);
    return value != 'false'; // default true
  }

  Future<void> setBlockScreenshots(bool block) =>
      writeString(_keyBlockScreenshots, block.toString());

  Future<bool> getBlockScreenshots() async {
    final value = await readString(_keyBlockScreenshots);
    return value == 'true';
  }

  Future<void> setLanguageCode(String code) =>
      writeString(_keyLanguageCode, code);

  Future<String?> getLanguageCode() => readString(_keyLanguageCode);
}

final securePrefsProvider = Provider<SecurePrefs>((ref) {
  return SecurePrefs();
});
