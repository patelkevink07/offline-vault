import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../storage/secure_prefs.dart';
import '../utils/logger.dart';

class PinVerificationResult {
  const PinVerificationResult({
    required this.success,
    this.isLockedOut = false,
    this.remainingLockout,
    this.failedAttempts = 0,
    this.errorMessage,
  });

  final bool success;
  final bool isLockedOut;
  final Duration? remainingLockout;
  final int failedAttempts;
  final String? errorMessage;
}

class PinService {
  PinService({
    required SecurePrefs prefs,
    LocalAuthentication? localAuth,
  })  : _prefs = prefs,
        _localAuth = localAuth ?? LocalAuthentication();

  final SecurePrefs _prefs;
  final LocalAuthentication _localAuth;

  static const int minPinLength = 4;
  static const int maxPinLength = 8;
  static const int defaultIterations = 100000;
  static const int saltLength = 16;

  static final RegExp _pinFormat = RegExp(r'^\d{4,8}$');

  /// Validates PIN format (4 to 8 digits numeric).
  bool isValidPinFormat(String pin) => _pinFormat.hasMatch(pin);

  /// Checks if a PIN is currently configured.
  Future<bool> hasPin() async => _prefs.hasPin();

  /// Returns remaining lockout duration if locked out, or null if not locked out.
  Future<Duration?> getRemainingLockout() async {
    final lockedUntil = await _prefs.getPinLockoutUntil();
    if (lockedUntil == null) return null;

    final now = DateTime.now();
    if (now.isBefore(lockedUntil)) {
      return lockedUntil.difference(now);
    } else {
      await _prefs.setPinLockoutUntil(null);
      return null;
    }
  }

  /// Calculates escalating lockout duration based on failed attempts:
  /// 5 attempts: 30s
  /// 6 attempts: 1m (60s)
  /// 7 attempts: 5m (300s)
  /// 8 attempts: 15m (900s)
  /// 9+ attempts: 1h (3600s)
  Duration getLockoutDurationForAttempts(int attempts) {
    if (attempts < 5) return Duration.zero;
    switch (attempts) {
      case 5:
        return const Duration(seconds: 30);
      case 6:
        return const Duration(minutes: 1);
      case 7:
        return const Duration(minutes: 5);
      case 8:
        return const Duration(minutes: 15);
      default:
        return const Duration(hours: 1);
    }
  }

  /// Hashes a PIN using PBKDF2-HMAC-SHA256 with 256-bit output.
  Future<Uint8List> derivePbkdf2Hash({
    required String pin,
    required Uint8List salt,
    int iterations = defaultIterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Constant-time byte array comparison to prevent timing attacks.
  bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Verifies an input PIN against stored credentials.
  /// Handles lockout checking, constant-time verification, lockout escalation,
  /// and transparent migration from legacy format (salt == 'salt').
  Future<PinVerificationResult> verifyPin(String inputPin) async {
    // 1. Check lockout state
    final remainingLockout = await getRemainingLockout();
    if (remainingLockout != null) {
      return PinVerificationResult(
        success: false,
        isLockedOut: true,
        remainingLockout: remainingLockout,
        errorMessage: 'Locked out due to too many failed attempts',
      );
    }

    final pinData = await _prefs.getPinHashAndSalt();
    final storedHash = pinData.hash;
    final storedSalt = pinData.salt;
    final iterations = pinData.iterations;

    if (storedHash == null || storedSalt == null) {
      return const PinVerificationResult(
        success: false,
        errorMessage: 'No PIN is set',
      );
    }

    bool isMatch = false;

    // 2. Detect legacy migration
    if (storedSalt == 'salt') {
      // Legacy format stored raw PIN as hash with literal 'salt'
      isMatch = constantTimeEquals(
        utf8.encode(storedHash),
        utf8.encode(inputPin),
      );

      if (isMatch) {
        // Upgrade immediately to PBKDF2
        await _savePbkdf2Pin(inputPin);
      }
    } else {
      // Modern PBKDF2 format
      try {
        final saltBytes = _hexToBytes(storedSalt);
        final expectedHashBytes = _hexToBytes(storedHash);
        final computedHashBytes = await derivePbkdf2Hash(
          pin: inputPin,
          salt: saltBytes,
          iterations: iterations,
        );

        isMatch = constantTimeEquals(expectedHashBytes, computedHashBytes);
      } catch (e, st) {
        VaultLogger.e('Error during PIN verification computation', e, st);
        isMatch = false;
      }
    }

    // 3. Handle success or failure with lockout
    if (isMatch) {
      await _prefs.setFailedPinAttempts(0);
      await _prefs.setPinLockoutUntil(null);
      return const PinVerificationResult(success: true);
    } else {
      final currentAttempts = (await _prefs.getFailedPinAttempts()) + 1;
      await _prefs.setFailedPinAttempts(currentAttempts);

      Duration? lockout;
      if (currentAttempts >= 5) {
        lockout = getLockoutDurationForAttempts(currentAttempts);
        final lockUntil = DateTime.now().add(lockout);
        await _prefs.setPinLockoutUntil(lockUntil);
      }

      return PinVerificationResult(
        success: false,
        isLockedOut: currentAttempts >= 5,
        remainingLockout: lockout,
        failedAttempts: currentAttempts,
        errorMessage: 'Incorrect PIN',
      );
    }
  }

  /// Sets a new PIN. If a PIN already exists, [currentPin] is required to verify.
  Future<void> setPin({
    required String newPin,
    String? currentPin,
  }) async {
    if (!isValidPinFormat(newPin)) {
      throw ArgumentError('PIN must be between 4 and 8 digits');
    }

    if (await hasPin()) {
      if (currentPin == null) {
        throw StateError('Current PIN is required to change or update PIN');
      }
      final result = await verifyPin(currentPin);
      if (!result.success) {
        if (result.isLockedOut) {
          throw StateError('Locked out due to too many failed attempts');
        }
        throw ArgumentError('Current PIN is incorrect');
      }
    }

    await _savePbkdf2Pin(newPin);
  }

  /// Changes existing PIN to a new PIN after verifying [currentPin].
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    await setPin(newPin: newPin, currentPin: currentPin);
  }

  /// Removes existing PIN after verifying [currentPin].
  Future<void> removePin(String currentPin) async {
    final result = await verifyPin(currentPin);
    if (!result.success) {
      if (result.isLockedOut) {
        throw StateError('Locked out due to too many failed attempts');
      }
      throw ArgumentError('Current PIN is incorrect');
    }

    await _prefs.clearPin();
    await _prefs.setBiometricsEnabled(false);
  }

  /// Checks if device supports biometrics and user has enabled biometrics.
  Future<bool> canUseBiometrics() async {
    final enabled = await _prefs.getBiometricsEnabled();
    if (!enabled) return false;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e, st) {
      VaultLogger.e('Error checking biometric availability', e, st);
      return false;
    }
  }

  /// Sets whether biometrics unlock is enabled.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefs.setBiometricsEnabled(enabled);
  }

  /// Authenticate using biometrics for unlocking the app.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to unlock vaultOFF',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e, st) {
      VaultLogger.e('Biometric authentication failed', e, st);
      return false;
    }
  }

  Future<void> _savePbkdf2Pin(String pin) async {
    final random = Random.secure();
    final saltBytes = Uint8List.fromList(
      List<int>.generate(saltLength, (_) => random.nextInt(256)),
    );

    final hashBytes = await derivePbkdf2Hash(
      pin: pin,
      salt: saltBytes,
      iterations: defaultIterations,
    );

    await _prefs.setPinHash(
      hash: _bytesToHex(hashBytes),
      salt: _bytesToHex(saltBytes),
      iterations: defaultIterations,
    );
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _hexToBytes(String hex) {
    final length = hex.length;
    final result = Uint8List(length ~/ 2);
    for (var i = 0; i < length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final prefs = ref.watch(securePrefsProvider);
  return PinService(prefs: prefs);
});
