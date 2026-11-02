import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/crypto/crypto_service.dart';
import 'package:offline_vault/core/crypto/key_manager.dart';
import 'package:offline_vault/data/models/compression_quality.dart';
import 'package:offline_vault/data/models/file_sync_state.dart';
import 'package:offline_vault/data/models/member_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  group('Models & Enums Unit Tests', () {
    test('FileSyncState enum has expected values', () {
      expect(FileSyncState.values, contains(FileSyncState.remote));
      expect(FileSyncState.values, contains(FileSyncState.queued));
      expect(FileSyncState.values, contains(FileSyncState.downloading));
      expect(FileSyncState.values, contains(FileSyncState.ready));
      expect(FileSyncState.values, contains(FileSyncState.failed));
    });

    test('MemberRole has correct permissions and values', () {
      expect(MemberRole.owner.canEdit, isTrue);
      expect(MemberRole.editor.canEdit, isTrue);
      expect(MemberRole.viewer.canEdit, isFalse);
    });

    test('CompressionQuality values and presets', () {
      expect(CompressionQuality.high.maxDimension, 4096);
      expect(CompressionQuality.high.jpegQuality, 85);
      expect(CompressionQuality.dataSaver.maxDimension, 2048);
      expect(CompressionQuality.dataSaver.jpegQuality, 60);
    });
  });

  group('Crypto Service Unit Tests', () {
    test('AES-256-GCM round trip encrypt and decrypt', () async {
      final keyManager = KeyManager();
      final crypto = CryptoService(keyManager: keyManager);
      await crypto.init();

      final originalData = Uint8List.fromList('Offline Vault Secure Data Payload'.codeUnits);
      final encrypted = await crypto.encryptFile(originalData);

      expect(encrypted, isNot(equals(originalData)));
      expect(encrypted.length, greaterThan(originalData.length)); // Nonce (12) + tag (16)

      final decrypted = await crypto.decryptFile(encrypted);
      expect(decrypted, equals(originalData));
    });
  });
}
