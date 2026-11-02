import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../remote/groups_remote_source.dart';
import '../remote/supabase_client.dart';

final groupsRemoteSourceProvider = Provider<GroupsRemoteSource>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return GroupsRemoteSource(supabase: supabase);
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final remote = ref.watch(groupsRemoteSourceProvider);
  return GroupsRepository(db: db, remote: remote);
});

class GroupsRepository {
  GroupsRepository({
    required AppDatabase db,
    required GroupsRemoteSource remote,
  })  : _db = db,
        _remote = remote;

  final AppDatabase _db;
  final GroupsRemoteSource _remote;

  /// Watch local groups from Drift DB (Local-first)
  Stream<List<LocalGroup>> watchGroups() => _db.groupsDao.watchAll();

  /// Create a new group via RPC and cache locally
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String color,
  }) async {
    final result = await _remote.createGroup(name: name, color: color);
    final groupData = result['group'] as Map<String, dynamic>;
    final groupId = groupData['id'] as String;

    await _db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: groupId,
        name: name,
        color: Value(color),
        myRole: const Value('owner'),
      ),
    );

    return result;
  }

  /// Join a group with code via RPC and cache locally
  Future<Map<String, dynamic>> joinGroup(String code) async {
    final result = await _remote.joinGroup(code);
    final groupData = result['group'] as Map<String, dynamic>;
    final groupId = groupData['id'] as String;
    final groupName = groupData['name'] as String;
    final groupColor = groupData['color'] as String;

    await _db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: groupId,
        name: groupName,
        color: Value(groupColor),
        myRole: const Value('viewer'),
      ),
    );

    return result;
  }
}
