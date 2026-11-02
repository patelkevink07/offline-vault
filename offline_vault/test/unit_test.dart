import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/crypto/crypto_service.dart';
import 'package:offline_vault/core/crypto/key_manager.dart';
import 'package:offline_vault/data/local/database.dart';
import 'package:offline_vault/data/models/compression_quality.dart';
import 'package:offline_vault/data/models/file_sync_state.dart';
import 'package:offline_vault/data/models/member_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
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
      expect(MemberRole.viewer.canEdit, isTrue);
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

  group('Drift Local Database & Document Naming Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Can create vault, folder, and store named documents locally', () async {
      // 1. Insert Vault
      await db.groupsDao.upsert(
        LocalGroupsCompanion.insert(
          id: 'vault-1',
          name: 'My Personal Vault',
          color: const Value('#0F5C5A'),
          myRole: const Value('owner'),
        ),
      );

      final groups = await db.groupsDao.watchAll().first;
      expect(groups.length, 1);
      expect(groups.first.name, 'My Personal Vault');

      // 2. Insert Folder inside Vault
      await db.foldersDao.upsert(
        LocalFoldersCompanion.insert(
          id: 'folder-1',
          groupId: 'vault-1',
          name: 'Identity Documents',
          updatedAt: DateTime.now(),
        ),
      );

      final folders = await db.foldersDao.watchByGroup('vault-1').first;
      expect(folders.length, 1);
      expect(folders.first.name, 'Identity Documents');

      // 3. Insert Named Document
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-101',
          groupId: 'vault-1',
          folderId: const Value('folder-1'),
          name: 'Passport_2026_Scanned.pdf',
          mime: 'application/pdf',
          size: 1048576,
          checksum: 'sha256-dummy-hash',
          thumbState: const Value('ready'),
          originalState: const Value('ready'),
          localOriginalPath: const Value('/vault/storage/passport.enc'),
          updatedAt: DateTime.now(),
        ),
      );

      final files = await db.filesDao.watchByGroup('vault-1', folderId: 'folder-1').first;
      expect(files.length, 1);
      expect(files.first.name, 'Passport_2026_Scanned.pdf');

      // 4. Search files by custom name
      final searchResults = await db.filesDao.search('Passport');
      expect(searchResults.length, 1);
      expect(searchResults.first.name, 'Passport_2026_Scanned.pdf');
    });

    test('UploadQueue persists custom named items and updates status', () async {
      await db.uploadQueueDao.enqueue(
        UploadQueueCompanion.insert(
          id: 'queue-1',
          groupId: 'vault-1',
          localPath: '/tmp/scan.pdf',
          name: 'Tax Return FY2025.pdf',
          mime: 'application/pdf',
          createdAt: DateTime.now(),
        ),
      );

      final pending = await db.uploadQueueDao.getPending();
      expect(pending.length, 1);
      expect(pending.first.name, 'Tax Return FY2025.pdf');

      await db.uploadQueueDao.updateState('queue-1', 'done');
      final updatedPending = await db.uploadQueueDao.getPending();
      expect(updatedPending.isEmpty, isTrue);
    });
  });
}
