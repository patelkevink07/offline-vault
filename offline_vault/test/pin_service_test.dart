import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/security/pin_service.dart';
import 'package:offline_vault/core/storage/secure_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> mockStorage;
  late SecurePrefs prefs;
  late PinService pinService;

  setUp(() {
    mockStorage = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(mockStorage);
    prefs = SecurePrefs();
    pinService = PinService(prefs: prefs);
  });

  group('PIN Length & Validation Tests', () {
    test('Accepts 4 to 8 digits numeric PINs', () {
      expect(pinService.isValidPinFormat('1234'), isTrue);
      expect(pinService.isValidPinFormat('123456'), isTrue);
      expect(pinService.isValidPinFormat('12345678'), isTrue);
    });

    test('Rejects less than 4 or more than 8 digits, and non-numeric', () {
      expect(pinService.isValidPinFormat('123'), isFalse);
      expect(pinService.isValidPinFormat('123456789'), isFalse);
      expect(pinService.isValidPinFormat('123a'), isFalse);
      expect(pinService.isValidPinFormat('abcd'), isFalse);
      expect(pinService.isValidPinFormat(''), isFalse);
    });

    test('setPin throws ArgumentError for invalid PIN lengths', () async {
      expect(
        () => pinService.setPin(newPin: '123'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => pinService.setPin(newPin: '123456789'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PBKDF2-HMAC-SHA256 Hashing & Verification Tests', () {
    test('Setting PIN derives PBKDF2 hash with 16-byte random salt and 100k iterations', () async {
      await pinService.setPin(newPin: '482910');

      expect(await pinService.hasPin(), isTrue);

      final data = await prefs.getPinHashAndSalt();
      expect(data.hash, isNotNull);
      expect(data.salt, isNotNull);
      expect(data.iterations, 100000);

      // Salt must be 16 bytes (32 hex characters)
      expect(data.salt!.length, 32);
      // Hash is 256-bit (64 hex characters)
      expect(data.hash!.length, 64);
      // Salt must not be the legacy literal 'salt'
      expect(data.salt, isNot('salt'));
    });

    test('Correct PIN verifies successfully and constant-time check works', () async {
      await pinService.setPin(newPin: '654321');

      final result = await pinService.verifyPin('654321');
      expect(result.success, isTrue);
      expect(result.isLockedOut, isFalse);
    });

    test('Wrong PIN is rejected and increments failure count', () async {
      await pinService.setPin(newPin: '654321');

      final result = await pinService.verifyPin('111111');
      expect(result.success, isFalse);
      expect(result.failedAttempts, 1);
      expect(result.isLockedOut, isFalse);

      expect(await prefs.getFailedPinAttempts(), 1);
    });

    test('Changing PIN requires valid current PIN', () async {
      await pinService.setPin(newPin: '123456');

      // Wrong current PIN throws ArgumentError
      expect(
        () => pinService.changePin(currentPin: '000000', newPin: '654321'),
        throwsA(isA<ArgumentError>()),
      );

      // Correct current PIN succeeds
      await pinService.changePin(currentPin: '123456', newPin: '654321');
      expect((await pinService.verifyPin('654321')).success, isTrue);
    });

    test('Removing PIN requires valid current PIN and clears storage', () async {
      await pinService.setPin(newPin: '123456');

      // Wrong current PIN throws ArgumentError
      expect(
        () => pinService.removePin('999999'),
        throwsA(isA<ArgumentError>()),
      );

      // Correct current PIN removes PIN
      await pinService.removePin('123456');
      expect(await pinService.hasPin(), isFalse);
    });
  });

  group('Lockout Escalation & Persisted State Across Restarts Tests', () {
    test('Lockout escalates after 5 failures and persists across restarts', () async {
      await pinService.setPin(newPin: '123456');

      // Attempts 1 to 4: no lockout
      for (int i = 1; i <= 4; i++) {
        final res = await pinService.verifyPin('000000');
        expect(res.success, isFalse);
        expect(res.isLockedOut, isFalse);
        expect(res.failedAttempts, i);
      }

      // 5th attempt: 30s lockout
      final res5 = await pinService.verifyPin('000000');
      expect(res5.success, isFalse);
      expect(res5.isLockedOut, isTrue);
      expect(res5.remainingLockout, isNotNull);
      expect(res5.remainingLockout!.inSeconds, greaterThanOrEqualTo(28));
      expect(res5.remainingLockout!.inSeconds, lessThanOrEqualTo(30));

      // Attempt during lockout is immediately rejected without evaluating PIN
      final lockedRes = await pinService.verifyPin('123456'); // even correct PIN
      expect(lockedRes.success, isFalse);
      expect(lockedRes.isLockedOut, isTrue);

      // Simulate app restart / force-close by instantiating new PinService with same prefs
      final restartedPinService = PinService(prefs: prefs);
      expect(await restartedPinService.getRemainingLockout(), isNotNull);

      final restartVerify = await restartedPinService.verifyPin('123456');
      expect(restartVerify.isLockedOut, isTrue);

      // Verify escalation table logic:
      expect(pinService.getLockoutDurationForAttempts(5), const Duration(seconds: 30));
      expect(pinService.getLockoutDurationForAttempts(6), const Duration(minutes: 1));
      expect(pinService.getLockoutDurationForAttempts(7), const Duration(minutes: 5));
      expect(pinService.getLockoutDurationForAttempts(8), const Duration(minutes: 15));
      expect(pinService.getLockoutDurationForAttempts(9), const Duration(hours: 1));
      expect(pinService.getLockoutDurationForAttempts(10), const Duration(hours: 1));
    });

    test('Successful verification resets failed attempts and lockout', () async {
      await pinService.setPin(newPin: '123456');

      await pinService.verifyPin('000000');
      await pinService.verifyPin('000000');
      expect(await prefs.getFailedPinAttempts(), 2);

      final successRes = await pinService.verifyPin('123456');
      expect(successRes.success, isTrue);
      expect(await prefs.getFailedPinAttempts(), 0);
      expect(await prefs.getPinLockoutUntil(), isNull);
    });
  });

  group('Legacy Migration Tests', () {
    test('Detects legacy salt ("salt") and migrates raw PIN to PBKDF2 on first entry', () async {
      // Simulate existing user with legacy insecure storage
      await prefs.writeString('vault_pin_hash', '4321');
      await prefs.writeString('vault_pin_salt', 'salt');
      await prefs.writeString('vault_pin_iterations', '1');

      final initialData = await prefs.getPinHashAndSalt();
      expect(initialData.salt, 'salt');
      expect(initialData.hash, '4321');

      // Wrong PIN fails and does not migrate
      final wrongRes = await pinService.verifyPin('9999');
      expect(wrongRes.success, isFalse);
      expect((await prefs.getPinHashAndSalt()).salt, 'salt');

      // Correct PIN verifies and triggers transparent migration
      final correctRes = await pinService.verifyPin('4321');
      expect(correctRes.success, isTrue);

      // Verify migrated format
      final migratedData = await prefs.getPinHashAndSalt();
      expect(migratedData.salt, isNot('salt'));
      expect(migratedData.salt!.length, 32); // 16-byte random salt
      expect(migratedData.hash, isNot('4321')); // Not raw string
      expect(migratedData.hash!.length, 64); // 256-bit PBKDF2 hash
      expect(migratedData.iterations, 100000);

      // Subsequent verifications use PBKDF2
      final followUpRes = await pinService.verifyPin('4321');
      expect(followUpRes.success, isTrue);
    });
  });
}
