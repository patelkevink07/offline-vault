import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/network/connectivity_service.dart';
import 'package:offline_vault/core/storage/file_storage_service.dart';
import 'package:offline_vault/data/local/database.dart';
import 'package:offline_vault/data/remote/groups_remote_source.dart';
import 'package:offline_vault/data/repositories/files_repository.dart';
import 'package:offline_vault/data/repositories/folders_repository.dart';
import 'package:offline_vault/data/repositories/upload_queue_repository.dart';
import 'package:offline_vault/sync/sync_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUser extends Fake implements User {
  @override
  String get id => 'test-user-id';
}

class MockGoTrueClient extends Fake implements GoTrueClient {
  User? mockCurrentUser = MockUser();

  @override
  User? get currentUser => mockCurrentUser;
}

class MockStorageFileApi extends Fake implements StorageFileApi {
  @override
  Future<String> createSignedUrl(
    String path,
    int expiresIn, {
    TransformOptions? transform,
    dynamic download,
  }) async {
    return 'https://example.com/fake/$path';
  }
}

class MockSupabaseStorageClient extends Fake implements SupabaseStorageClient {
  final _api = MockStorageFileApi();

  @override
  StorageFileApi from(String id) => _api;
}

class MockSupabaseClient extends Fake implements SupabaseClient {
  final _auth = MockGoTrueClient();
  final _storage = MockSupabaseStorageClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseStorageClient get storage => _storage;
}

class FakeConnectivityService extends Fake implements ConnectivityService {
  bool onlineState = true;

  @override
  Future<bool> get isOnline async => onlineState;
}

class FakeUploadQueueRepository extends Fake implements UploadQueueRepository {}

class FakeFileStorageService extends Fake implements FileStorageService {
  final List<String> deletedPaths = [];

  @override
  Future<String> getOriginalsPath(String groupId) async =>
      '/fake/storage/$groupId/originals';

  @override
  Future<String> getThumbsPath(String groupId) async =>
      '/fake/storage/$groupId/thumbs';

  @override
  Future<void> deleteFile(String path) async {
    deletedPaths.add(path);
  }

  @override
  Future<String> writeEncryptedFile({
    required String filePath,
    required Uint8List plainBytes,
  }) async {
    return filePath;
  }
}

class FakeGroupsRemoteSource extends Fake implements GroupsRemoteSource {
  final List<String> softDeletedFiles = [];
  final List<String> softDeletedFolders = [];
  bool rejectWithError = false;

  @override
  Future<List<SignedUrl>> createSignedUrls({
    required List<String> paths,
    int expiresInSeconds = 3600,
  }) async {
    return paths.map((p) => SignedUrl(path: p, signedUrl: 'https://example.com/$p')).toList();
  }

  @override
  Future<void> softDeleteFile(String fileId) async {
    if (rejectWithError) {
      throw Exception('Permission denied by RLS policy');
    }
    softDeletedFiles.add(fileId);
  }

  @override
  Future<void> softDeleteFolder(String folderId) async {
    if (rejectWithError) {
      throw Exception('Permission denied by RLS policy');
    }
    softDeletedFolders.add(folderId);
  }

  @override
  Future<List<Map<String, dynamic>>> pullFolders({
    required String groupId,
    DateTime? sinceCursor,
    int offset = 0,
    int limit = 200,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> pullFiles({
    required String groupId,
    DateTime? sinceCursor,
    int offset = 0,
    int limit = 200,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchAllFolders({
    required String groupId,
    DateTime? sinceCursor,
    int pageSize = 200,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchAllFiles({
    required String groupId,
    DateTime? sinceCursor,
    int pageSize = 200,
  }) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeGroupsRemoteSource remoteSource;
  late FakeFileStorageService storageService;
  late FakeConnectivityService connectivityService;
  late MockSupabaseClient supabaseClient;
  late SyncEngine syncEngine;
  late FilesRepository filesRepo;
  late FoldersRepository foldersRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteSource = FakeGroupsRemoteSource();
    storageService = FakeFileStorageService();
    connectivityService = FakeConnectivityService();
    supabaseClient = MockSupabaseClient();

    syncEngine = SyncEngine(
      db: db,
      supabase: supabaseClient,
      remoteSource: remoteSource,
      uploadQueueRepo: FakeUploadQueueRepository(),
      storageService: storageService,
      connectivity: connectivityService,
    );

    filesRepo = FilesRepository(
      db: db,
      storage: storageService,
      syncEngine: syncEngine,
    );

    foldersRepo = FoldersRepository(
      db: db,
      supabase: supabaseClient,
      syncEngine: syncEngine,
    );

    // Pre-insert parent group
    await db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: 'group-1',
        name: 'Secret Vault',
        color: const Value('#0F5C5A'),
        myRole: const Value('owner'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3: Soft-Delete & Delete Queue Tests', () {
    test('Offline delete enqueues to DeleteQueue and hides immediately locally', () async {
      // 1. Create file locally
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-101',
          groupId: 'group-1',
          name: 'Passport.jpg',
          mime: 'image/jpeg',
          size: 2048,
          checksum: 'chk-101',
          thumbState: const Value('ready'),
          originalState: const Value('ready'),
          localThumbPath: const Value('/storage/thumb-101.webp'),
          localOriginalPath: const Value('/storage/orig-101.jpg'),
          updatedAt: DateTime.parse('2026-11-03T09:00:00.000Z'),
        ),
      );

      // Verify file is visible initially
      var visibleFiles = await db.filesDao.watchByGroup('group-1').first;
      expect(visibleFiles.length, 1);

      // Make offline
      connectivityService.onlineState = false;

      // 2. Perform delete
      await filesRepo.deleteFile(fileId: 'file-101', groupId: 'group-1');

      // 3. Immediately hidden locally
      visibleFiles = await db.filesDao.watchByGroup('group-1').first;
      expect(visibleFiles, isEmpty);

      // Item is in delete queue
      final queueItems = await db.deleteQueueDao.getPending();
      expect(queueItems.length, 1);
      expect(queueItems.first.targetId, 'file-101');
      expect(queueItems.first.targetType, 'file');

      // Remote source not yet called because offline
      expect(remoteSource.softDeletedFiles, isEmpty);

      // 4. Reconnect and process queue
      connectivityService.onlineState = true;
      await syncEngine.processDeleteQueue();

      // Remote soft-delete was called
      expect(remoteSource.softDeletedFiles, contains('file-101'));

      // Cleaned up from disk and delete queue
      expect(storageService.deletedPaths, contains('/storage/orig-101.jpg'));
      expect(storageService.deletedPaths, contains('/storage/thumb-101.webp'));
      final remainingQueue = await db.deleteQueueDao.getPending();
      expect(remainingQueue, isEmpty);

      // Record is marked isDeleted
      final file = await db.filesDao.getById('file-101');
      expect(file?.isDeleted, isTrue);
    });

    test('Viewer "Remove from this phone" deletes original from disk and retains thumbnail', () async {
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-202',
          groupId: 'group-1',
          name: 'Report.pdf',
          mime: 'application/pdf',
          size: 5000,
          checksum: 'chk-202',
          thumbState: const Value('ready'),
          originalState: const Value('ready'),
          localThumbPath: const Value('/storage/thumb-202.webp'),
          localOriginalPath: const Value('/storage/orig-202.pdf'),
          updatedAt: DateTime.parse('2026-11-03T09:00:00.000Z'),
        ),
      );

      // Viewer triggers remove from phone
      await filesRepo.removeFromThisPhone(
        fileId: 'file-202',
        localOriginalPath: '/storage/orig-202.pdf',
      );

      // Original deleted from disk, thumb NOT deleted
      expect(storageService.deletedPaths, contains('/storage/orig-202.pdf'));
      expect(storageService.deletedPaths, isNot(contains('/storage/thumb-202.webp')));

      // State updated in database: originalState = remote, localOriginalPath = null, thumb retained
      final file = await db.filesDao.getById('file-202');
      expect(file?.originalState, 'remote');
      expect(file?.localOriginalPath, isNull);
      expect(file?.localThumbPath, '/storage/thumb-202.webp');
      expect(file?.thumbState, 'ready');

      // Still visible in gallery!
      final visible = await db.filesDao.watchByGroup('group-1').first;
      expect(visible.length, 1);
      expect(visible.first.id, 'file-202');
    });

    test('Folder delete marks folder and all child files pendingDelete and enqueues to queue', () async {
      // 1. Create folder
      await db.foldersDao.upsert(
        LocalFoldersCompanion.insert(
          id: 'folder-1',
          groupId: 'group-1',
          name: 'Tax 2026',
          updatedAt: DateTime.parse('2026-11-03T09:00:00.000Z'),
        ),
      );

      // 2. Create files in folder
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-child-1',
          groupId: 'group-1',
          folderId: const Value('folder-1'),
          name: 'W2.pdf',
          mime: 'application/pdf',
          size: 1024,
          checksum: 'chk-child-1',
          updatedAt: DateTime.parse('2026-11-03T09:00:00.000Z'),
        ),
      );
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-child-2',
          groupId: 'group-1',
          folderId: const Value('folder-1'),
          name: '1099.pdf',
          mime: 'application/pdf',
          size: 2048,
          checksum: 'chk-child-2',
          updatedAt: DateTime.parse('2026-11-03T09:00:00.000Z'),
        ),
      );

      connectivityService.onlineState = false;

      // 3. Delete folder
      await foldersRepo.deleteFolder(folderId: 'folder-1', groupId: 'group-1');

      // Folder and children hidden from active queries
      final folders = await db.foldersDao.watchByGroup('group-1').first;
      expect(folders, isEmpty);

      final filesInFolder = await db.filesDao.watchByGroup('group-1', folderId: 'folder-1').first;
      expect(filesInFolder, isEmpty);

      // Queue contains folder
      final queue = await db.deleteQueueDao.getPending();
      expect(queue.length, 1);
      expect(queue.first.targetId, 'folder-1');
      expect(queue.first.targetType, 'folder');

      // Reconnect and process
      connectivityService.onlineState = true;
      await syncEngine.processDeleteQueue();

      expect(remoteSource.softDeletedFolders, contains('folder-1'));
      final remainingQueue = await db.deleteQueueDao.getPending();
      expect(remainingQueue, isEmpty);

      // Both folder and child files are marked isDeleted
      final folderRow = await (db.select(db.localFolders)..where((t) => t.id.equals('folder-1'))).getSingle();
      expect(folderRow.isDeleted, isTrue);

      final child1 = await db.filesDao.getById('file-child-1');
      expect(child1?.isDeleted, isTrue);
      final child2 = await db.filesDao.getById('file-child-2');
      expect(child2?.isDeleted, isTrue);
    });

    test('Server rejection (RLS failure) restores file locally and clears from queue', () async {
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-protected',
          groupId: 'group-1',
          name: 'Protected.pdf',
          mime: 'application/pdf',
          size: 1024,
          checksum: 'chk-prot',
          updatedAt: DateTime.parse('2026-11-03T09:00:00.000Z'),
        ),
      );

      // Queue delete
      await filesRepo.deleteFile(fileId: 'file-protected', groupId: 'group-1');

      // Remote rejects with permission error
      remoteSource.rejectWithError = true;
      await syncEngine.processDeleteQueue();

      // Restored locally
      final file = await db.filesDao.getById('file-protected');
      expect(file?.pendingDelete, isFalse);
      expect(file?.isDeleted, isFalse);

      // Visible in gallery again
      final visible = await db.filesDao.watchByGroup('group-1').first;
      expect(visible.map((f) => f.id), contains('file-protected'));

      // Queue is cleared
      final queue = await db.deleteQueueDao.getPending();
      expect(queue, isEmpty);
    });
  });
}
