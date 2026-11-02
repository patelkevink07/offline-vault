import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/connectivity_service.dart';
import '../core/storage/file_storage_service.dart';
import '../core/utils/logger.dart';
import '../data/local/database.dart';
import '../data/remote/groups_remote_source.dart';
import '../data/repositories/upload_queue_repository.dart';

enum SyncTrigger {
  manual,
  connectivityChanged,
  appOpened,
  backgroundPeriodic,
}

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
    int bytesDown = 0;
    int bytesUp = 0;

    try {
      // 1. Check network connectivity
      final isOnline = await _connectivity.isOnline;
      if (!isOnline) {
        VaultLogger.i('Device is offline. Halting sync cycle.');
        _isRunning = false;
        return false;
      }

      // 2. Push upload queue
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

      // 3. Pull metadata for all active groups
      final userGroups = await _remote.fetchUserGroups();
      final activeGroupIds = <String>{};

      for (final membership in userGroups) {
        final groupData = membership['groups'] as Map<String, dynamic>;
        final groupId = groupData['id'] as String;
        final myRole = membership['role'] as String;
        activeGroupIds.add(groupId);

        // Upsert group into Drift
        await _db.groupsDao.upsert(
          LocalGroupsCompanion.insert(
            id: groupId,
            name: groupData['name'] as String,
            color: Value(groupData['color'] as String),
            myRole: Value(myRole),
          ),
        );

        final localGroup = await _db.groupsDao.getById(groupId);
        final cursor = localGroup?.lastSyncCursor;

        // Pull folders
        final remoteFolders = await _remote.pullFolders(
          groupId: groupId,
          sinceCursor: cursor,
        );
        for (final folder in remoteFolders) {
          final isDeleted = folder['deleted'] as bool? ?? false;
          if (isDeleted) {
            await _db.foldersDao.deleteById(folder['id'] as String);
          } else {
            await _db.foldersDao.upsert(
              LocalFoldersCompanion.insert(
                id: folder['id'] as String,
                groupId: groupId,
                parentId: Value(folder['parent_id'] as String?),
                name: folder['name'] as String,
                updatedAt: DateTime.parse(folder['updated_at'] as String),
              ),
            );
          }
        }

        // Pull files
        final remoteFiles = await _remote.pullFiles(
          groupId: groupId,
          sinceCursor: cursor,
        );
        for (final rf in remoteFiles) {
          final isDeleted = rf['deleted'] as bool? ?? false;
          final fileId = rf['id'] as String;

          if (isDeleted) {
            await _db.filesDao.deleteById(fileId);
            final localOriginal = '${await _storage.getOriginalsPath(groupId)}/$fileId';
            final localThumb = '${await _storage.getThumbsPath(groupId)}/$fileId.webp';
            await _storage.deleteFile(localOriginal);
            await _storage.deleteFile(localThumb);
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

        // Update sync cursor to current time
        await _db.groupsDao.updateSyncCursor(groupId, DateTime.now());
      }

      // 4. Purge locally removed groups
      final allLocalGroups = await _db.groupsDao.getAll();
      for (final lg in allLocalGroups) {
        if (!activeGroupIds.contains(lg.id)) {
          VaultLogger.i('Purging local data for removed group: ${lg.id}');
          await _db.groupsDao.deleteGroup(lg.id);
          await _storage.purgeGroup(lg.id);
        }
      }

      // 5. Download missing thumbnails first (smallest first)
      final missingThumbs = await (_db.select(_db.localFiles)
            ..where((t) => t.thumbState.equals('queued') | t.thumbState.equals('remote'))
            ..orderBy([(t) => OrderingTerm.asc(t.size)]))
          .get();

      for (final file in missingThumbs) {
        try {
          final thumbStoragePath = '${file.groupId}/thumbs/${file.id}.webp';
          // ignore: deprecated_member_use
          final signedUrls = await _supabase.storage.from('vault').createSignedUrls([thumbStoragePath], 3600);
          if (signedUrls.isNotEmpty) {
            final downloadUrl = signedUrls.first.signedUrl;
            final response = await _dio.get<List<int>>(
              downloadUrl,
              options: Options(responseType: ResponseType.bytes),
            );

            if (response.data != null) {
              final rawBytes = Uint8List.fromList(response.data!);
              final localThumbPath = '${await _storage.getThumbsPath(file.groupId)}/${file.id}.webp';
              await _storage.writeEncryptedFile(
                filePath: localThumbPath,
                plainBytes: rawBytes,
              );

              await _db.filesDao.updateThumbState(
                file.id,
                'ready',
                localPath: localThumbPath,
              );
              bytesDown += rawBytes.length;
            }
          }
        } catch (e) {
          VaultLogger.w('Failed to download thumbnail for ${file.id}', e);
        }
      }

      // 6. Download originals (newest first, with resumable Range headers)
      final missingOriginals = await (_db.select(_db.localFiles)
            ..where((t) => t.originalState.equals('queued'))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

      for (final file in missingOriginals) {
        try {
          final originalStoragePath = '${file.groupId}/originals/${file.id}';
          // ignore: deprecated_member_use
          final signedUrls = await _supabase.storage.from('vault').createSignedUrls([originalStoragePath], 3600);
          if (signedUrls.isNotEmpty) {
            final downloadUrl = signedUrls.first.signedUrl;
            final localOriginalPath = '${await _storage.getOriginalsPath(file.groupId)}/${file.id}';
            final partFilePath = '$localOriginalPath.part';

            final partFile = File(partFilePath);
            int existingLength = 0;
            if (partFile.existsSync()) {
              existingLength = partFile.lengthSync();
            }

            final response = await _dio.get<List<int>>(
              downloadUrl,
              options: Options(
                responseType: ResponseType.bytes,
                headers: existingLength > 0 ? {'Range': 'bytes=$existingLength-'} : null,
              ),
            );

            if (response.data != null) {
              final receivedBytes = Uint8List.fromList(response.data!);
              await partFile.writeAsBytes(receivedBytes, mode: FileMode.append, flush: true);

              final completePlainBytes = await partFile.readAsBytes();
              final computedChecksum = sha256.convert(completePlainBytes).toString();

              if (computedChecksum == file.checksum) {
                // Encrypt and persist
                await _storage.writeEncryptedFile(
                  filePath: localOriginalPath,
                  plainBytes: completePlainBytes,
                );
                await partFile.delete();

                await _db.filesDao.updateOriginalState(
                  file.id,
                  'ready',
                  localPath: localOriginalPath,
                );
                bytesDown += completePlainBytes.length;
              } else {
                VaultLogger.w('Checksum mismatch for downloaded file ${file.id}');
                await partFile.delete();
              }
            }
          }
        } catch (e) {
          VaultLogger.w('Failed to download original for ${file.id}', e);
        }
      }

      // 7. Log sync cycle completion
      await _db.syncLogDao.insertLog(
        SyncLogCompanion.insert(
          startedAt: startTime,
          endedAt: Value(DateTime.now()),
          bytesDown: Value(bytesDown),
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
}
