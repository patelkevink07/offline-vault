import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/file_storage_service.dart';
import '../../sync/sync_engine.dart';
import '../local/database.dart';

final filesRepositoryProvider = Provider<FilesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final storage = ref.watch(fileStorageProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return FilesRepository(
    db: db,
    storage: storage,
    syncEngine: syncEngine,
  );
});

class FilesRepository {
  FilesRepository({
    required AppDatabase db,
    required FileStorageService storage,
    required SyncEngine syncEngine,
  })  : _db = db,
        _storage = storage,
        _syncEngine = syncEngine;

  final AppDatabase _db;
  final FileStorageService _storage;
  final SyncEngine _syncEngine;

  /// Watch active files in a group or folder (excluding pending and soft-deleted).
  Stream<List<LocalFile>> watchFiles(String groupId, {String? folderId}) {
    return _db.filesDao.watchByGroup(groupId, folderId: folderId);
  }

  /// Search files by name/note (excluding pending and soft-deleted).
  Future<List<LocalFile>> searchFiles(String query) {
    return _db.filesDao.search(query);
  }

  /// Soft-delete a file for owner/editor.
  /// Immediately hides the file locally, enqueues to persistent delete queue,
  /// and triggers sync to propagate to the server.
  Future<void> deleteFile({
    required String fileId,
    required String groupId,
  }) async {
    // 1. Mark pending delete locally (hides from gallery, viewer, search)
    await _db.filesDao.markPendingDelete(fileId);

    // 2. Add to persistent delete queue
    await _db.deleteQueueDao.enqueue(
      id: const Uuid().v4(),
      targetId: fileId,
      groupId: groupId,
      targetType: 'file',
    );

    // 3. Trigger immediate sync to process delete queue
    _syncEngine.processDeleteQueue().ignore();
  }

  /// Viewer action: deletes only the local decrypted/original file from this device,
  /// retains the thumbnail, and sets state to 'remote'.
  Future<void> removeFromThisPhone({
    required String fileId,
    required String? localOriginalPath,
  }) async {
    if (localOriginalPath != null) {
      await _storage.deleteFile(localOriginalPath);
    }
    await _db.filesDao.removeOriginalFromPhone(fileId);
  }
}
