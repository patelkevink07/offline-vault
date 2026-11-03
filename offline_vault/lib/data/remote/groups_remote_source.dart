import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';

/// Remote data source for groups, folders, files, and invite RPCs.
class GroupsRemoteSource {
  GroupsRemoteSource({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Call RPC create_group(p_name, p_color)
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String color,
  }) async {
    VaultLogger.i('Calling create_group RPC...');
    final response = await _supabase.rpc(
      'create_group',
      params: {
        'p_name': name,
        'p_color': color,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// Call RPC join_group(p_code)
  Future<Map<String, dynamic>> joinGroup(String code) async {
    VaultLogger.i('Calling join_group RPC...');
    final response = await _supabase.rpc(
      'join_group',
      params: {
        'p_code': code,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// Call RPC get_invite_code(p_group_id)
  Future<Map<String, dynamic>?> getInviteCode(String groupId) async {
    final response = await _supabase.rpc(
      'get_invite_code',
      params: {
        'p_group_id': groupId,
      },
    );
    if (response == null) return null;
    return Map<String, dynamic>.from(response as Map);
  }

  /// Call RPC rotate_invite_code(p_group_id, p_expires_in)
  Future<Map<String, dynamic>> rotateInviteCode({
    required String groupId,
    String? expiresIn,
  }) async {
    final response = await _supabase.rpc(
      'rotate_invite_code',
      params: {
        'p_group_id': groupId,
        if (expiresIn != null) 'p_expires_in': expiresIn,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// Call RPC set_invite_code_state
  Future<void> setInviteCodeState({
    required String groupId,
    required bool enabled,
    DateTime? expiresAt,
  }) async {
    await _supabase.rpc(
      'set_invite_code_state',
      params: {
        'p_group_id': groupId,
        'p_enabled': enabled,
        if (expiresAt != null) 'p_expires_at': expiresAt.toIso8601String(),
      },
    );
  }

  /// Fetch active group memberships for the current user.
  Future<List<Map<String, dynamic>>> fetchUserGroups() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('group_members')
        .select('group_id, role, status, groups(id, name, color, owner_id, created_at, updated_at)')
        .eq('user_id', userId)
        .eq('status', 'active');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Fetch all members for a group.
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    final response = await _supabase
        .from('group_members')
        .select('group_id, user_id, role, status, joined_at, profiles(display_name, email, avatar_url)')
        .eq('group_id', groupId)
        .neq('status', 'removed')
        .order('joined_at', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Change member role (owner only)
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    await _supabase
        .from('group_members')
        .update({'role': role})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  /// Remove member from group (owner only)
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _supabase
        .from('group_members')
        .update({'status': 'removed'})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  /// Leave group (current user)
  Future<void> leaveGroup({
    required String groupId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('group_members')
        .update({'status': 'removed'})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  /// Approve pending member (owner only)
  Future<void> approveMember({
    required String groupId,
    required String userId,
  }) async {
    await _supabase.rpc(
      'approve_member',
      params: {
        'p_group_id': groupId,
        'p_user_id': userId,
      },
    );
  }

  /// Decline pending member (owner only)
  Future<void> declineMember({
    required String groupId,
    required String userId,
  }) async {
    await _supabase.rpc(
      'decline_member',
      params: {
        'p_group_id': groupId,
        'p_user_id': userId,
      },
    );
  }

  /// Pull metadata for folders since cursor, ordered by (updated_at, id) with pagination
  Future<List<Map<String, dynamic>>> pullFolders({
    required String groupId,
    DateTime? sinceCursor,
    int offset = 0,
    int limit = 200,
  }) async {
    var query = _supabase
        .from('folders')
        .select()
        .eq('group_id', groupId);

    if (sinceCursor != null) {
      final bufferCursor = sinceCursor.subtract(const Duration(minutes: 5));
      query = query.gt('updated_at', bufferCursor.toIso8601String());
    }

    final response = await query
        .order('updated_at', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all folders for a group across pages of 200
  Future<List<Map<String, dynamic>>> fetchAllFolders({
    required String groupId,
    DateTime? sinceCursor,
    int pageSize = 200,
  }) async {
    final allRows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await pullFolders(
        groupId: groupId,
        sinceCursor: sinceCursor,
        offset: offset,
        limit: pageSize,
      );
      allRows.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return allRows;
  }

  /// Pull metadata for files since cursor, ordered by (updated_at, id) with pagination
  Future<List<Map<String, dynamic>>> pullFiles({
    required String groupId,
    DateTime? sinceCursor,
    int offset = 0,
    int limit = 200,
  }) async {
    var query = _supabase
        .from('files')
        .select()
        .eq('group_id', groupId);

    if (sinceCursor != null) {
      final bufferCursor = sinceCursor.subtract(const Duration(minutes: 5));
      query = query.gt('updated_at', bufferCursor.toIso8601String());
    }

    final response = await query
        .order('updated_at', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all files for a group across pages of 200
  Future<List<Map<String, dynamic>>> fetchAllFiles({
    required String groupId,
    DateTime? sinceCursor,
    int pageSize = 200,
  }) async {
    final allRows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await pullFiles(
        groupId: groupId,
        sinceCursor: sinceCursor,
        offset: offset,
        limit: pageSize,
      );
      allRows.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return allRows;
  }

  /// Request short-lived signed URLs for a batch of storage paths.
  Future<List<SignedUrl>> createSignedUrls({
    required List<String> paths,
    int expiresInSeconds = 3600,
  }) async {
    // ignore: deprecated_member_use
    return _supabase.storage.from('vault').createSignedUrls(
      paths,
      expiresInSeconds,
    );
  }

  /// Soft-delete a file on the server (allowed for owner and editor by RLS).
  Future<void> softDeleteFile(String fileId) async {
    await _supabase
        .from('files')
        .update({
          'deleted': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', fileId);
  }

  /// Soft-delete a folder and all its contents on the server.
  Future<void> softDeleteFolder(String folderId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _supabase
        .from('folders')
        .update({
          'deleted': true,
          'updated_at': now,
        })
        .eq('id', folderId);

    await _supabase
        .from('files')
        .update({
          'deleted': true,
          'updated_at': now,
        })
        .eq('folder_id', folderId);
  }
}
