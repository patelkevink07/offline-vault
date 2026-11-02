import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_manager.dart';

/// Provides AES-256-GCM encryption and decryption for files.
///
/// Each encryption produces a fresh random 96-bit nonce. The output format
/// is: `nonce (12 bytes) + ciphertext + tag (16 bytes)`.
class CryptoService {
  CryptoService({required KeyManager keyManager}) : _keyManager = keyManager;

  final KeyManager _keyManager;
  final AesGcm _algorithm = AesGcm.with256bits();

  /// The length of the nonce in bytes (96 bits).
  static const int _nonceLength = 12;

  /// The length of the authentication tag in bytes (128 bits).
  static const int _tagLength = 16;

  SecretKey? _cachedKey;

  /// Initialize or load the master key. Must be called at app startup.
  Future<void> init() async {
    _cachedKey = await _keyManager.getOrCreateKey();
  }

  /// Returns the current master key, loading it if necessary.
  Future<SecretKey> _getKey() async {
    _cachedKey ??= await _keyManager.getOrCreateKey();
    return _cachedKey!;
  }

  /// Alias for [encryptFile]
  Future<Uint8List> encrypt(Uint8List plainBytes) => encryptFile(plainBytes);

  /// Alias for [decryptFile]
  Future<Uint8List> decrypt(Uint8List encryptedBytes) => decryptFile(encryptedBytes);

  /// Encrypt [plainBytes] with AES-256-GCM.
  ///
  /// Returns `nonce (12 B) || ciphertext || tag (16 B)`.
  Future<Uint8List> encryptFile(Uint8List plainBytes) async {
    final key = await _getKey();
    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: key,
    );

    final nonce = secretBox.nonce;
    final cipherText = secretBox.cipherText;
    final mac = secretBox.mac.bytes;

    // Pack: nonce + ciphertext + tag
    final output = Uint8List(_nonceLength + cipherText.length + _tagLength);
    output.setRange(0, _nonceLength, nonce);
    output.setRange(_nonceLength, _nonceLength + cipherText.length, cipherText);
    output.setRange(
      _nonceLength + cipherText.length,
      output.length,
      mac,
    );

    return output;
  }

  /// Decrypt [encryptedBytes] that was produced by [encryptFile].
  ///
  /// Expects format: `nonce (12 B) || ciphertext || tag (16 B)`.
  /// Throws if the data is too short or authentication fails.
  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    if (encryptedBytes.length < _nonceLength + _tagLength) {
      throw const FormatException(
        'Encrypted data is too short to contain nonce and tag',
      );
    }

    final key = await _getKey();

    final nonce = encryptedBytes.sublist(0, _nonceLength);
    final cipherText = encryptedBytes.sublist(
      _nonceLength,
      encryptedBytes.length - _tagLength,
    );
    final mac = Mac(encryptedBytes.sublist(encryptedBytes.length - _tagLength));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final plainBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(plainBytes);
  }

  /// Wipe the cached key from memory. Call on sign-out.
  void dispose() {
    _cachedKey = null;
  }
}

/// Riverpod provider for [CryptoService].
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final keyManager = ref.watch(keyManagerProvider);
  final service = CryptoService(keyManager: keyManager);
  ref.onDispose(service.dispose);
  return service;
});
