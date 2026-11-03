import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../core/network/connectivity_service.dart';
import '../core/storage/file_storage_service.dart';
import '../core/utils/logger.dart';
import '../data/local/database.dart';
import '../data/remote/groups_remote_source.dart';
import '../data/remote/supabase_client.dart';
import '../data/repositories/groups_repository.dart';
import '../data/repositories/upload_queue_repository.dart';

enum SyncTrigger {
  manual,
  connectivityChanged,
  appOpened,
  backgroundPeriodic,
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final remoteSource = ref.watch(groupsRemoteSourceProvider);
  final uploadQueueRepo = ref.watch(uploadQueueRepositoryProvider);
  final storageService = ref.watch(fileStorageProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return SyncEngine(
    db: db,
    supabase: supabase,
    remoteSource: remoteSource,
    uploadQueueRepo: uploadQueueRepo,
    storageService: storageService,
    connectivity: connectivity,
  );
});

class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SupabaseClient supabase,
    required GroupsRemoteSource remoteSource,
    required UploadQueueRepository uploadQueueRepo,
    required FileStorageService storageService,
    required ConnectivityService connectivity,
  })  : _db = db,
        _supabase = supabase,
        _remote = remoteSource,
        _uploadQueue = uploadQueueRepo,
        _storage = storageService,
        _connectivity = connectivity;

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final GroupsRemoteSource _remote;
  final UploadQueueRepository _uploadQueue;
  final FileStorageService _storage;
  final ConnectivityService _connectivity;
  final Dio _dio = Dio();

  static bool _isRunning = false;

  /// Main sync cycle execution guarded by singleton mutex
  Future<bool> run({required SyncTrigger trigger}) async {
    if (_isRunning) {
      VaultLogger.i('Sync is already running, skipping trigger: $trigger');
      return false;
    }

    _isRunning = true;
    VaultLogger.i('Starting sync engine cycle triggered by $trigger');
    final startTime = DateTime.now();
    const int bytesDown = 0;
    int bytesUp = 0;

    try {
      // 1. Process pending upload queue regardless of cloud auth
      final pendingUploads = await _db.uploadQueueDao.getPending();
      for (final item in pendingUploads) {
        final success = await _uploadQueue.processQueueItem(
          item: item,
          storageService: _storage,
        );
        if (success) {
          bytesUp += File(item.localPath).existsSync()
              ? File(item.localPath).lengthSync()
              : 0;
        }
      }

      // 2. Check network connectivity & cloud auth
      final isOnline = await _connectivity.isOnline;
      final currentUser = _supabase.auth.currentUser;
      if (!isOnline || currentUser == null) {
        VaultLogger.i('Device offline or user not signed into cloud. Local sync complete.');
        _isRunning = false;
        return true;
      }

      // One-time migration: reset all existing cursors to null once so next sync does a safe re-pull
      final prefs = await SharedPreferences.getInstance();
      final cursorResetDone = prefs.getBool('sync_cursor_v2_reset_done') ?? false;
      if (!cursorResetDone) {
        await _db.groupsDao.resetAllSyncCursors();
        await prefs.setBool('sync_cursor_v2_reset_done', true);
        VaultLogger.i('Phase 2 migration: reset existing sync cursors to null once.');
      }

      // 3. Pull metadata for all active cloud groups
      final userGroups = await _remote.fetchUserGroups();

      for (final membership in userGroups) {
        final groupData = membership['groups'] as Map<String, dynamic>?;
        if (groupData == null) continue;
        final groupId = groupData['id'] as String;
        final myRole = (membership['role'] as String?) ?? 'editor';

        // Upsert group into Drift SQLite
        await _db.groupsDao.upsert(
          LocalGroupsCompanion.insert(
            id: groupId,
            name: groupData['name'] as String,
            color: Value(groupData['color'] as String? ?? '#0F5C5A'),
            myRole: Value(myRole),
          ),
        );

        // Sync folders and files for this group
        await syncGroup(groupId);
      }

      // Log sync cycle completion
      await _db.syncLogDao.insertLog(
        SyncLogCompanion.insert(
          startedAt: startTime,
          endedAt: Value(DateTime.now()),
          bytesDown: const Value(bytesDown),
          bytesUp: Value(bytesUp),
          result: const Value('success'),
        ),
      );

      VaultLogger.i('Sync cycle finished successfully.');
      _isRunning = false;
      return true;
    } catch (e, st) {
      VaultLogger.e('Sync cycle failed with error', e, st);
      _isRunning = false;
      return false;
    }
  }

  /// Sync folders, files, and thumbnails for a specific group using server updated_at cursor
  Future<void> syncGroup(String groupId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // 0. Read current group cursor from local SQLite
      final localGroup = await _db.groupsDao.getById(groupId);
      final currentCursor = localGroup?.lastSyncCursor;
      final currentCursorId = localGroup?.lastSyncCursorId;

      // 1. Pull folders in pages of 200 ordered by (updated_at, id)
      final remoteFolders = await _remote.fetchAllFolders(
        groupId: groupId,
        sinceCursor: currentCursor,
      );

      // 2. Pull files in pages of 200 ordered by (updated_at, id)
      final remoteFiles = await _remote.fetchAllFiles(
        groupId: groupId,
        sinceCursor: currentCursor,
      );

      // 3. Track maximum server (updated_at, id) actually received across all rows
      DateTime? maxServerUpdatedAt = currentCursor;
      String? maxServerId = currentCursorId;

      void trackMax(String? updatedAtStr, String? id) {
        if (updatedAtStr == null || id == null) return;
        final serverTime = DateTime.parse(updatedAtStr);
        if (maxServerUpdatedAt == null || serverTime.isAfter(maxServerUpdatedAt!)) {
          maxServerUpdatedAt = serverTime;
          maxServerId = id;
        } else if (serverTime.isAtSameMomentAs(maxServerUpdatedAt!)) {
          if (maxServerId == null || id.compareTo(maxServerId!) > 0) {
            maxServerUpdatedAt = serverTime;
            maxServerId = id;
          }
        }
      }

      for (final folder in remoteFolders) {
        trackMax(folder['updated_at'] as String?, folder['id'] as String?);
      }
      for (final rf in remoteFiles) {
        trackMax(rf['updated_at'] as String?, rf['id'] as String?);
      }

      // 4. Apply pages as idempotent upserts and soft-deletes inside ONE Drift transaction
      await _db.transaction(() async {
        // Apply folders
        for (final folder in remoteFolders) {
          final isDeleted = folder['deleted'] as bool? ?? false;
          final folderId = folder['id'] as String;
          if (isDeleted) {
            await _db.foldersDao.deleteById(folderId);
          } else {
            await _db.foldersDao.upsert(
              LocalFoldersCompanion.insert(
                id: folderId,
                groupId: groupId,
                parentId: Value(folder['parent_id'] as String?),
                name: folder['name'] as String,
                updatedAt: DateTime.parse(folder['updated_at'] as String),
              ),
            );
          }
        }

        // Apply files
        for (final rf in remoteFiles) {
          final isDeleted = rf['deleted'] as bool? ?? false;
          final fileId = rf['id'] as String;

          if (isDeleted) {
            await _db.filesDao.deleteById(fileId);
          } else {
            final existing = await _db.filesDao.getById(fileId);
            await _db.filesDao.upsert(
              LocalFilesCompanion.insert(
                id: fileId,
                groupId: groupId,
                folderId: Value(rf['folder_id'] as String?),
                name: rf['name'] as String,
                note: Value(rf['note'] as String?),
                mime: rf['mime_type'] as String,
                size: (rf['size_bytes'] as num).toInt(),
                checksum: rf['checksum'] as String,
                width: Value(rf['width'] as int?),
                height: Value(rf['height'] as int?),
                thumbState: Value(existing?.thumbState ?? 'queued'),
                originalState: Value(existing?.originalState ?? 'remote'),
                localThumbPath: Value(existing?.localThumbPath),
                localOriginalPath: Value(existing?.localOriginalPath),
                updatedAt: DateTime.parse(rf['updated_at'] as String),
              ),
            );
          }
        }
      });

      // 5. Clean up local files on disk for soft-deleted files
      for (final rf in remoteFiles) {
        final isDeleted = rf['deleted'] as bool? ?? false;
        if (isDeleted) {
          final fileId = rf['id'] as String;
          final localOriginal = '${await _storage.getOriginalsPath(groupId)}/$fileId';
          final localThumb = '${await _storage.getThumbsPath(groupId)}/$fileId.webp';
          await _storage.deleteFile(localOriginal);
          await _storage.deleteFile(localThumb);
        }
      }

      // 6. Update the cursor only AFTER that transaction commits
      if (maxServerUpdatedAt != null &&
          (maxServerUpdatedAt != currentCursor || maxServerId != currentCursorId)) {
        await _db.groupsDao.updateSyncCursor(
          groupId,
          maxServerUpdatedAt!,
          cursorId: maxServerId,
        );
      }

      // 7. Download missing thumbnails & originals for this group
      final query = _db.select(_db.localFiles)
        ..where(
          (t) =>
              t.groupId.equals(groupId) &
              (t.originalState.equals('remote') |
                  t.originalState.equals('queued') |
                  t.localOriginalPath.isNull()),
        );
      final filesNeedingDownload = await query.get();

      for (final file in filesNeedingDownload) {
        await downloadFile(file);
      }
    } catch (e, st) {
      VaultLogger.e('Failed to sync group $groupId', e, st);
    }
  }

  /// Download a file from cloud storage, encrypt it locally with AES-256, and save to SQLite
  Future<bool> downloadFile(LocalFile file) async {
    try {
      final originalStoragePath = '${file.groupId}/originals/${file.id}';
      // ignore: deprecated_member_use
      final signedUrls = await _supabase.storage.from('vault').createSignedUrls([originalStoragePath], 3600);

      if (signedUrls.isEmpty || signedUrls.first.signedUrl.isEmpty) {
        return false;
      }

      final downloadUrl = signedUrls.first.signedUrl;
      final localOriginalPath = '${await _storage.getOriginalsPath(file.groupId)}/${file.id}';

      final response = await _dio.get<List<int>>(
        downloadUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final rawBytes = Uint8List.fromList(response.data!);

        // Encrypt with local device keystore AES-256
        await _storage.writeEncryptedFile(
          filePath: localOriginalPath,
          plainBytes: rawBytes,
        );

        String? localThumbPath;
        if (file.mime.startsWith('image/')) {
          localThumbPath = localOriginalPath;
        }

        await _db.filesDao.upsert(
          LocalFilesCompanion.insert(
            id: file.id,
            groupId: file.groupId,
            folderId: Value(file.folderId),
            name: file.name,
            mime: file.mime,
            size: file.size,
            checksum: file.checksum,
            originalState: const Value('ready'),
            thumbState: const Value('ready'),
            localOriginalPath: Value(localOriginalPath),
            localThumbPath: Value(localThumbPath),
            updatedAt: file.updatedAt,
          ),
        );

        return true;
      }
    } catch (e) {
      VaultLogger.w('Failed to download file ${file.id}: $e');
    }
    return false;
  }
}
