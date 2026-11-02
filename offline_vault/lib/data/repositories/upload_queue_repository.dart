import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/file_storage_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/media_service.dart';
import '../local/database.dart';
import '../models/compression_quality.dart';
import '../remote/supabase_client.dart';

final uploadQueueRepositoryProvider = Provider<UploadQueueRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return UploadQueueRepository(db: db, supabase: supabase);
});

class UploadQueueRepository {
  UploadQueueRepository({
    required AppDatabase db,
    required SupabaseClient supabase,
  })  : _db = db,
        _supabase = supabase;

  final AppDatabase _db;
  final SupabaseClient _supabase;

  /// Watch pending/uploading queue items
  Stream<List<UploadQueueData>> watchQueue(String groupId) {
    return _db.uploadQueueDao.watchPending();
  }

  /// Add a file to local upload queue
  Future<String> enqueueFile({
    required String localPath,
    required String groupId,
    String? folderId,
    required String name,
    required String mime,
  }) async {
    final queueId = const Uuid().v4();
    await _db.uploadQueueDao.insertItem(
      UploadQueueCompanion.insert(
        id: queueId,
        localPath: localPath,
        groupId: groupId,
        folderId: Value(folderId),
        name: name,
        mime: mime,
        state: const Value('pending'),
        bytesSent: const Value(0),
        attempts: const Value(0),
        createdAt: DateTime.now(),
      ),
    );
    return queueId;
  }

  /// Enqueue and process a file immediately (offline-first, no stream race condition)
  Future<bool> enqueueAndProcessFile({
    required String localPath,
    required String groupId,
    String? folderId,
    required String name,
    required String mime,
    required FileStorageService storageService,
    CompressionQuality quality = CompressionQuality.high,
  }) async {
    final queueId = const Uuid().v4();
    final companion = UploadQueueCompanion.insert(
      id: queueId,
      localPath: localPath,
      groupId: groupId,
      folderId: Value(folderId),
      name: name,
      mime: mime,
      state: const Value('pending'),
      bytesSent: const Value(0),
      attempts: const Value(0),
      createdAt: DateTime.now(),
    );
    await _db.uploadQueueDao.insertItem(companion);

    final item = await (_db.select(_db.uploadQueue)..where((t) => t.id.equals(queueId))).getSingle();
    return processQueueItem(
      item: item,
      storageService: storageService,
      quality: quality,
    );
  }

  /// Process the next item in the upload queue
  Future<bool> processQueueItem({
    required UploadQueueData item,
    required FileStorageService storageService,
    CompressionQuality quality = CompressionQuality.high,
  }) async {
    VaultLogger.i('Processing upload for ${item.name} (${item.id})');
    await _db.uploadQueueDao.updateState(item.id, 'uploading', bytesSent: 0);

    try {
      final originalFile = File(item.localPath);
      if (!originalFile.existsSync()) {
        throw Exception('Source file no longer exists');
      }

      final fileId = const Uuid().v4();
      final isImage = item.mime.startsWith('image/');

      // 1. Compression and thumbnail generation
      File fileToUpload = originalFile;
      Uint8List? thumbBytes;

      if (isImage) {
        fileToUpload = await MediaService.compressImage(
          sourceFile: originalFile,
          quality: quality,
        );
        thumbBytes = await MediaService.generateThumbnail(fileToUpload);
      }

      // 2. Compute checksum (SHA-256)
      final rawBytes = await fileToUpload.readAsBytes();
      final checksum = sha256.convert(rawBytes).toString();

      // Check for duplicate checksum in this group
      final existingFile = await (_db.select(_db.localFiles)
            ..where((t) => t.groupId.equals(item.groupId) & t.checksum.equals(checksum)))
          .getSingleOrNull();

      if (existingFile != null) {
        VaultLogger.i('De-duplicating upload: file already exists with same checksum');
        await _db.uploadQueueDao.updateState(item.id, 'done');
        return true;
      }

      // 3. Store encrypted files locally first (Offline-first guarantee)
      String? localThumbPath;
      if (thumbBytes != null) {
        localThumbPath = '${await storageService.getThumbsPath(item.groupId)}/$fileId.webp';
        await storageService.writeEncryptedFile(
          filePath: localThumbPath,
          plainBytes: thumbBytes,
        );
      }

      final localOriginalPath = '${await storageService.getOriginalsPath(item.groupId)}/$fileId';
      await storageService.writeEncryptedFile(
        filePath: localOriginalPath,
        plainBytes: rawBytes,
      );

      // 4. Optionally upload to Supabase if signed into cloud
      DateTime updatedAt = DateTime.now();
      String? thumbStoragePath;
      String? originalStoragePath;
      if (_supabase.auth.currentUser != null) {
        try {
          if (thumbBytes != null) {
            thumbStoragePath = '${item.groupId}/thumbs/$fileId.webp';
            await _supabase.storage.from('vault').uploadBinary(
                  thumbStoragePath,
                  thumbBytes,
                  fileOptions: const FileOptions(upsert: true, contentType: 'image/webp'),
                );
          }

          originalStoragePath = '${item.groupId}/originals/$fileId';
          await _supabase.storage.from('vault').uploadBinary(
                originalStoragePath,
                rawBytes,
                fileOptions: FileOptions(upsert: true, contentType: item.mime),
              );

          final insertedRow = await _supabase.from('files').insert({
            'id': fileId,
            'group_id': item.groupId,
            'folder_id': item.folderId,
            'name': item.name,
            'mime_type': item.mime,
            'size_bytes': rawBytes.length,
            'checksum': checksum,
            'storage_path': originalStoragePath,
            'thumb_path': thumbStoragePath,
          }).select().single();

          updatedAt = DateTime.parse(insertedRow['updated_at'] as String);
        } catch (cloudErr) {
          VaultLogger.w('Cloud upload skipped or failed (offline/guest mode): $cloudErr');
        }
      }

      // 5. Insert into Drift local files table
      await _db.filesDao.upsert(
        LocalFilesCompanion.insert(
          id: fileId,
          groupId: item.groupId,
          folderId: Value(item.folderId),
          name: item.name,
          mime: item.mime,
          size: rawBytes.length,
          checksum: checksum,
          thumbState: const Value('ready'),
          originalState: const Value('ready'),
          localThumbPath: Value(localThumbPath),
          localOriginalPath: Value(localOriginalPath),
          updatedAt: updatedAt,
        ),
      );

      await _db.uploadQueueDao.updateState(item.id, 'done');
      VaultLogger.i('Upload successfully completed for file: $fileId');
      return true;
    } catch (e, st) {
      VaultLogger.e('Upload failed for ${item.id}', e, st);
      final newAttempts = item.attempts + 1;
      await _db.uploadQueueDao.updateAttempts(
        item.id,
        newAttempts,
        newAttempts >= 8 ? 'failed' : 'pending',
        error: e.toString(),
      );
      return false;
    }
  }
}
