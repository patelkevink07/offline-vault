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
  static const String _keyBiometricsEnabled = 'vault_biometrics_enabled';
  static const String _keySyncOnWifiOnly = 'vault_sync_wifi_only';
  static const String _keyBlockScreenshots = 'vault_block_screenshots';
  static const String _keyLanguageCode = 'vault_language_code';

  Future<void> writeString(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> deleteKey(String key) => _storage.delete(key: key);

  Future<void> setPinHash(String hash, String salt) async {
    await writeString(_keyPinHash, hash);
    await writeString(_keyPinSalt, salt);
  }

  Future<({String? hash, String? salt})> getPinHashAndSalt() async {
    final hash = await readString(_keyPinHash);
    final salt = await readString(_keyPinSalt);
    return (hash: hash, salt: salt);
  }

  Future<void> clearPin() async {
    await deleteKey(_keyPinHash);
    await deleteKey(_keyPinSalt);
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
