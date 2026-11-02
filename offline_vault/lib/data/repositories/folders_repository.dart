import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../remote/supabase_client.dart';

final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return FoldersRepository(db: db, supabase: supabase);
});

class FoldersRepository {
  FoldersRepository({
    required AppDatabase db,
    required SupabaseClient supabase,
  })  : _db = db,
        _supabase = supabase;

  final AppDatabase _db;
  final SupabaseClient _supabase;

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

  Future<void> deleteFolder(String folderId) async {
    try {
      await _supabase
          .from('folders')
          .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', folderId);
    } catch (_) {}
    await _db.foldersDao.deleteById(folderId);
  }
}
