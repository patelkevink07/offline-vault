import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/file_storage_service.dart';
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
  final storage = ref.watch(fileStorageProvider);
  return GroupsRepository(
    db: db,
    remote: remote,
    supabase: supabase,
    storage: storage,
  );
});

class GroupsRepository {
  GroupsRepository({
    required AppDatabase db,
    required GroupsRemoteSource remote,
    required SupabaseClient supabase,
    required FileStorageService storage,
  })  : _db = db,
        _remote = remote,
        _supabase = supabase,
        _storage = storage;

  final AppDatabase _db;
  final GroupsRemoteSource _remote;
  final SupabaseClient _supabase;
  final FileStorageService _storage;

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

  /// List all members for a group.
  Future<List<Map<String, dynamic>>> fetchMembers(String groupId) async {
    try {
      return await _remote.fetchGroupMembers(groupId);
    } catch (e) {
      VaultLogger.w('Failed to fetch group members: $e');
      return [];
    }
  }

  /// Change a member's role (owner only).
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    await _remote.updateMemberRole(
      groupId: groupId,
      userId: userId,
      role: role,
    );
    // If updating own role, reflect locally
    if (userId == _supabase.auth.currentUser?.id) {
      final current = await _db.groupsDao.getById(groupId);
      if (current != null) {
        await _db.groupsDao.upsert(
          current.toCompanion(true).copyWith(myRole: Value(role)),
        );
      }
    }
  }

  /// Remove a member from the group (owner only).
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _remote.removeMember(groupId: groupId, userId: userId);
    // If removing self, wipe local group
    if (userId == _supabase.auth.currentUser?.id) {
      await purgeLocalGroup(groupId);
    }
  }

  /// Leave group (non-owner). Wipes local files and group data immediately.
  Future<void> leaveGroup(String groupId) async {
    try {
      await _remote.leaveGroup(groupId: groupId);
    } catch (e) {
      VaultLogger.w('Remote leaveGroup error (wiping local data anyway): $e');
    }
    await purgeLocalGroup(groupId);
  }

  /// Wipes all files, thumbnails, and database records for a group from this device.
  Future<void> purgeLocalGroup(String groupId) async {
    // 1. Wipe storage files and thumbnails on disk
    await _storage.wipeGroupStorage(groupId);

    // 2. Cascade delete from local database
    await _db.groupsDao.deleteGroup(groupId);
  }

  /// Owner approves pending member.
  Future<void> approveMember({
    required String groupId,
    required String userId,
  }) async {
    await _remote.approveMember(groupId: groupId, userId: userId);
  }

  /// Owner declines pending member.
  Future<void> declineMember({
    required String groupId,
    required String userId,
  }) async {
    await _remote.declineMember(groupId: groupId, userId: userId);
  }
}
