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

    return List<Map<String, dynamic>>.from(response);
  }

  /// Pull metadata for folders since cursor
  Future<List<Map<String, dynamic>>> pullFolders({
    required String groupId,
    DateTime? sinceCursor,
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

    final response = await query.order('updated_at').limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Pull metadata for files since cursor
  Future<List<Map<String, dynamic>>> pullFiles({
    required String groupId,
    DateTime? sinceCursor,
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

    final response = await query.order('updated_at').limit(limit);
    return List<Map<String, dynamic>>.from(response);
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
}
