import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_engine.dart';
import '../local/database.dart';
import '../remote/supabase_client.dart';

final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return FoldersRepository(
    db: db,
    supabase: supabase,
    syncEngine: syncEngine,
  );
});

class FoldersRepository {
  FoldersRepository({
    required AppDatabase db,
    required SupabaseClient supabase,
    required SyncEngine syncEngine,
  })  : _db = db,
        _supabase = supabase,
        _syncEngine = syncEngine;

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SyncEngine _syncEngine;

  Stream<List<LocalFolder>> watchFolders(String groupId, {String? parentId}) {
    return _db.foldersDao.watchByGroup(groupId, parentId: parentId);
  }

  Future<void> createFolder({
    required String groupId,
    String? parentId,
    required String name,
  }) async {
    final folderId = const Uuid().v4();
    DateTime updatedAt = DateTime.now();

    try {
      final response = await _supabase.from('folders').insert({
        'id': folderId,
        'group_id': groupId,
        'parent_id': parentId,
        'name': name,
      }).select().single();
      updatedAt = DateTime.parse(response['updated_at'] as String);
    } catch (_) {
      // Offline fallback: save locally
    }

    await _db.foldersDao.upsert(
      LocalFoldersCompanion.insert(
        id: folderId,
        groupId: groupId,
        parentId: Value(parentId),
        name: name,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Soft-delete folder and all contained files in one queued operation.
  Future<void> deleteFolder({
    required String folderId,
    required String groupId,
  }) async {
    // 1. Mark folder as pendingDelete locally
    await _db.foldersDao.markPendingDelete(folderId);

    // 2. Mark all files in folder as pendingDelete locally
    final filesInFolder = await (_db.select(_db.localFiles)
          ..where((t) => t.folderId.equals(folderId)))
        .get();
    for (final f in filesInFolder) {
      await _db.filesDao.markPendingDelete(f.id);
    }

    // 3. Enqueue to persistent DeleteQueue
    await _db.deleteQueueDao.enqueue(
      id: const Uuid().v4(),
      targetId: folderId,
      groupId: groupId,
      targetType: 'folder',
    );

    // 4. Trigger sync engine
    _syncEngine.processDeleteQueue().ignore();
  }
}
