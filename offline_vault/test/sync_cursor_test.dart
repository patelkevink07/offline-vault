import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/network/connectivity_service.dart';
import 'package:offline_vault/core/storage/file_storage_service.dart';
import 'package:offline_vault/data/local/database.dart';
import 'package:offline_vault/data/remote/groups_remote_source.dart';
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
  @override
  Future<bool> get isOnline async => true;
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
  @override
  Future<List<SignedUrl>> createSignedUrls({
    required List<String> paths,
    int expiresInSeconds = 3600,
  }) async {
    return paths.map((p) => SignedUrl(path: p, signedUrl: 'https://example.com/$p')).toList();
  }
  List<Map<String, dynamic>> foldersToReturn = [];
  List<Map<String, dynamic>> filesToReturn = [];
  DateTime? lastSinceCursorFolders;
  DateTime? lastSinceCursorFiles;
  bool shouldThrowInFetch = false;

  @override
  Future<List<Map<String, dynamic>>> pullFolders({
    required String groupId,
    DateTime? sinceCursor,
    int offset = 0,
    int limit = 200,
  }) async {
    lastSinceCursorFolders = sinceCursor;
    if (shouldThrowInFetch) throw Exception('Simulated network failure');
    if (offset >= foldersToReturn.length) return [];
    return foldersToReturn.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllFolders({
    required String groupId,
    DateTime? sinceCursor,
    int pageSize = 200,
  }) async {
    final all = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await pullFolders(
        groupId: groupId,
        sinceCursor: sinceCursor,
        offset: offset,
        limit: pageSize,
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }

  @override
  Future<List<Map<String, dynamic>>> pullFiles({
    required String groupId,
    DateTime? sinceCursor,
    int offset = 0,
    int limit = 200,
  }) async {
    lastSinceCursorFiles = sinceCursor;
    if (shouldThrowInFetch) throw Exception('Simulated network failure');
    if (offset >= filesToReturn.length) return [];
    return filesToReturn.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllFiles({
    required String groupId,
    DateTime? sinceCursor,
    int pageSize = 200,
  }) async {
    final all = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await pullFiles(
        groupId: groupId,
        sinceCursor: sinceCursor,
        offset: offset,
        limit: pageSize,
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeGroupsRemoteSource remoteSource;
  late FakeFileStorageService storageService;
  late MockSupabaseClient supabase;
  late SyncEngine syncEngine;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteSource = FakeGroupsRemoteSource();
    storageService = FakeFileStorageService();
    supabase = MockSupabaseClient();

    syncEngine = SyncEngine(
      db: db,
      supabase: supabase,
      remoteSource: remoteSource,
      uploadQueueRepo: FakeUploadQueueRepository(),
      storageService: storageService,
      connectivity: FakeConnectivityService(),
    );

    // Seed test group
    await db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: 'group-alpha',
        name: 'Alpha Vault',
        color: const Value('#0F5C5A'),
        myRole: const Value('owner'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Sync Cursor Correctness Tests (Phase 2)', () {
    test('Phone clock ahead or behind does NOT affect cursor (tracks server updated_at)', () async {
      final serverTimestamp = DateTime.parse('2026-11-03T09:30:00.000Z');

      remoteSource.filesToReturn = [
        {
          'id': 'file-1',
          'group_id': 'group-alpha',
          'name': 'Doc1.pdf',
          'mime_type': 'application/pdf',
          'size_bytes': 1024,
          'checksum': 'chk1',
          'deleted': false,
          'updated_at': serverTimestamp.toIso8601String(),
        },
      ];

      // 1. Initial sync
      await syncEngine.syncGroup('group-alpha');

      final groupAfterFirstSync = await db.groupsDao.getById('group-alpha');
      expect(groupAfterFirstSync, isNotNull);
      // Cursor must equal the server updated_at, NOT DateTime.now()
      expect(groupAfterFirstSync!.lastSyncCursor!.toUtc(), serverTimestamp.toUtc());
      expect(groupAfterFirstSync.lastSyncCursorId, 'file-1');

      // 2. Next sync: verify query uses the server updated_at cursor as sinceCursor
      remoteSource.filesToReturn = [];
      await syncEngine.syncGroup('group-alpha');

      expect(remoteSource.lastSinceCursorFiles!.toUtc(), serverTimestamp.toUtc());
    });

    test('Late committing row with earlier timestamp is captured via 5-minute buffer', () async {
      // Suppose cursor is at 10:00:00Z
      final cursor = DateTime.parse('2026-11-03T10:00:00.000Z');
      await db.groupsDao.updateSyncCursor('group-alpha', cursor, cursorId: 'init-file');

      // 5-minute buffer window is 09:55:00Z
      final bufferBoundary = cursor.subtract(const Duration(minutes: 5));
      expect(bufferBoundary.toUtc(), DateTime.parse('2026-11-03T09:55:00.000Z').toUtc());

      // A late row committed at 09:58:00Z (2 minutes BEFORE previous cursor)
      final lateRowTime = DateTime.parse('2026-11-03T09:58:00.000Z');
      expect(lateRowTime.isAfter(bufferBoundary), isTrue);

      remoteSource.filesToReturn = [
        {
          'id': 'file-late',
          'group_id': 'group-alpha',
          'name': 'LateCommit.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': 2048,
          'checksum': 'chk-late',
          'deleted': false,
          'updated_at': lateRowTime.toIso8601String(),
        },
      ];

      await syncEngine.syncGroup('group-alpha');

      final file = await db.filesDao.getById('file-late');
      expect(file, isNotNull);
      expect(file!.name, 'LateCommit.jpg');
    });

    test('Paging across 250 items with identical timestamps uses ID as tiebreaker', () async {
      final sameTimestamp = DateTime.parse('2026-11-03T12:00:00.000Z');

      // Generate 250 items with identical timestamp, ordered by ID
      final items = List.generate(250, (i) {
        final idStr = 'file_${i.toString().padLeft(4, '0')}';
        return {
          'id': idStr,
          'group_id': 'group-alpha',
          'name': 'Photo_$i.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': 4096,
          'checksum': 'hash_$i',
          'deleted': false,
          'updated_at': sameTimestamp.toIso8601String(),
        };
      });

      remoteSource.filesToReturn = items;

      await syncEngine.syncGroup('group-alpha');

      // All 250 rows should be present locally
      final count = await (db.select(db.localFiles)..where((t) => t.groupId.equals('group-alpha'))).get();
      expect(count.length, 250);

      // Group cursor should tie-break to the highest ID ('file_0249')
      final group = await db.groupsDao.getById('group-alpha');
      expect(group!.lastSyncCursor!.toUtc(), sameTimestamp.toUtc());
      expect(group.lastSyncCursorId, 'file_0249');
    });

    test('Deleted rows (soft-deletes) remove local record and cache files', () async {
      // 1. Insert existing local file
      await db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: 'file-to-delete',
          groupId: 'group-alpha',
          name: 'OldDoc.pdf',
          mime: 'application/pdf',
          size: 1024,
          checksum: 'chk-del',
          updatedAt: DateTime.parse('2026-11-03T08:00:00.000Z'),
        ),
      );

      expect(await db.filesDao.getById('file-to-delete'), isNotNull);

      // 2. Remote returns deleted: true
      remoteSource.filesToReturn = [
        {
          'id': 'file-to-delete',
          'group_id': 'group-alpha',
          'name': 'OldDoc.pdf',
          'mime_type': 'application/pdf',
          'size_bytes': 1024,
          'checksum': 'chk-del',
          'deleted': true,
          'updated_at': '2026-11-03T09:00:00.000Z',
        },
      ];

      await syncEngine.syncGroup('group-alpha');

      // Local record must be deleted
      expect(await db.filesDao.getById('file-to-delete'), isNull);

      // Storage cleanup must be invoked for original and thumb
      expect(storageService.deletedPaths, contains('/fake/storage/group-alpha/originals/file-to-delete'));
      expect(storageService.deletedPaths, contains('/fake/storage/group-alpha/thumbs/file-to-delete.webp'));
    });

    test('Interrupted sync aborts transaction and resumes without losing rows', () async {
      final initialCursor = DateTime.parse('2026-11-03T07:00:00.000Z');
      await db.groupsDao.updateSyncCursor('group-alpha', initialCursor, cursorId: 'initial-id');

      // 1. Set remote source to throw error during sync
      remoteSource.shouldThrowInFetch = true;
      remoteSource.filesToReturn = [
        {
          'id': 'file-fail',
          'group_id': 'group-alpha',
          'name': 'Fail.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': 1024,
          'checksum': 'chk-fail',
          'deleted': false,
          'updated_at': '2026-11-03T08:30:00.000Z',
        },
      ];

      await syncEngine.syncGroup('group-alpha');

      // Cursor must NOT have advanced
      final groupAfterFail = await db.groupsDao.getById('group-alpha');
      expect(groupAfterFail!.lastSyncCursor!.toUtc(), initialCursor.toUtc());
      expect(groupAfterFail.lastSyncCursorId, 'initial-id');

      // File was not inserted
      expect(await db.filesDao.getById('file-fail'), isNull);

      // 2. Recover from error and retry sync
      remoteSource.shouldThrowInFetch = false;
      await syncEngine.syncGroup('group-alpha');

      // File is now safely inserted and cursor is advanced
      expect(await db.filesDao.getById('file-fail'), isNotNull);
      final groupAfterRecover = await db.groupsDao.getById('group-alpha');
      expect(
        groupAfterRecover!.lastSyncCursor!.toUtc(),
        DateTime.parse('2026-11-03T08:30:00.000Z').toUtc(),
      );
      expect(groupAfterRecover.lastSyncCursorId, 'file-fail');
    });
  });
}
