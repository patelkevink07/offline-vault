import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/logger.dart';
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
  final supabase = ref.watch(supabaseClientProvider);
  return GroupsRepository(db: db, remote: remote, supabase: supabase);
});

class GroupsRepository {
  GroupsRepository({
    required AppDatabase db,
    required GroupsRemoteSource remote,
    required SupabaseClient supabase,
  })  : _db = db,
        _remote = remote,
        _supabase = supabase;

  final AppDatabase _db;
  final GroupsRemoteSource _remote;
  final SupabaseClient _supabase;

  /// Watch local groups from Drift DB (Local-first)
  Stream<List<LocalGroup>> watchGroups() => _db.groupsDao.watchAll();

  /// Create a new group via RPC and cache locally, or create locally if offline.
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String color,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
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
      } catch (e) {
        VaultLogger.w('Cloud group creation failed, falling back to local: $e');
      }
    }

    // Offline fallback: create local vault in Drift database
    final localId = const Uuid().v4();
    await _db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: localId,
        name: name,
        color: Value(color),
        myRole: const Value('owner'),
      ),
    );
    return {
      'group': {
        'id': localId,
        'name': name,
        'color': color,
        'myRole': 'owner',
      },
    };
  }

  /// Join a group with code via RPC and cache locally, or create locally if offline.
  Future<Map<String, dynamic>> joinGroup(String code) async {
    final cleanCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim().toUpperCase();
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        final result = await _remote.joinGroup(cleanCode);
        final groupData = result['group'] as Map<String, dynamic>;
        final groupId = groupData['id'] as String;
        final groupName = groupData['name'] as String;
        final groupColor = (groupData['color'] as String?) ?? '#0F5C5A';

        await _db.groupsDao.upsert(
          LocalGroupsCompanion.insert(
            id: groupId,
            name: groupName,
            color: Value(groupColor),
            myRole: const Value('editor'),
          ),
        );

        return result;
      } catch (e) {
        VaultLogger.w('Cloud join group failed, falling back to local: $e');
      }
    }

    // Check if vault already exists locally
    final allGroups = await _db.groupsDao.getAll();
    final match = allGroups.where((g) {
      final normId = g.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      return normId.startsWith(cleanCode);
    }).firstOrNull;

    if (match != null) {
      return {
        'group': {
          'id': match.id,
          'name': match.name,
          'color': match.color,
          'myRole': 'editor',
        },
      };
    }

    // Offline fallback: create local joined group stub
    final localId = const Uuid().v4();
    final displayCode = cleanCode.length >= 4 ? cleanCode.substring(0, 4) : cleanCode;
    final groupName = 'Vault #$displayCode';
    await _db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: localId,
        name: groupName,
        color: const Value('#0F5C5A'),
        myRole: const Value('editor'),
      ),
    );
    return {
      'group': {
        'id': localId,
        'name': groupName,
        'color': '#0F5C5A',
        'myRole': 'editor',
      },
    };
  }
}
