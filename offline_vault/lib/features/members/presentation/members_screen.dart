import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../data/local/database.dart';
import '../../../data/remote/supabase_client.dart';
import '../../../data/repositories/groups_repository.dart';
import '../../../l10n/app_localizations.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String? _inviteCode;
  DateTime? _expiresAt;
  bool _requireApproval = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  LocalGroup? _localGroup;

  @override
  void initState() {
    super.initState();
    _loadGroupAndMembers();
  }

  Future<void> _loadGroupAndMembers() async {
    setState(() => _isLoading = true);

    final db = ref.read(databaseProvider);
    final repo = ref.read(groupsRepositoryProvider);
    final remote = ref.read(groupsRemoteSourceProvider);

    _localGroup = await db.groupsDao.getById(widget.groupId);

    try {
      final codeRes = await remote.getInviteCode(widget.groupId);
      if (codeRes != null && codeRes['code'] != null) {
        _inviteCode = codeRes['code'] as String;
        if (codeRes['expires_at'] != null) {
          _expiresAt = DateTime.tryParse(codeRes['expires_at'] as String);
        }
      } else {
        // Fallback: 4-digit numeric code from group ID or random
        final digits = widget.groupId.replaceAll(RegExp(r'[^0-9]'), '');
        _inviteCode = digits.length >= 4 ? digits.substring(0, 4) : '4829';
      }

      _members = await repo.fetchMembers(widget.groupId);
    } catch (_) {
      final digits = widget.groupId.replaceAll(RegExp(r'[^0-9]'), '');
      _inviteCode = digits.length >= 4 ? digits.substring(0, 4) : '4829';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool get _isOwner => _localGroup?.myRole == 'owner';

  String _formatExpiresIn(AppLocalizations l10n) {
    if (_expiresAt == null) return l10n.expiresInHours(24);
    final diff = _expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return l10n.invalidOrExpiredCode;
    final hours = diff.inHours;
    if (hours > 0) return l10n.expiresInHours(hours);
    return '${diff.inMinutes} m';
  }

  Future<void> _rotateCode([String? expiresIn]) async {
    final remote = ref.read(groupsRemoteSourceProvider);
    final l10n = AppLocalizations.of(context);
    try {
      final res = await remote.rotateInviteCode(
        groupId: widget.groupId,
        expiresIn: expiresIn ?? '24 hours',
      );
      if (res['code'] != null) {
        setState(() {
          _inviteCode = res['code'] as String;
          if (expiresIn == '1 hour') {
            _expiresAt = DateTime.now().add(const Duration(hours: 1));
          } else if (expiresIn == '7 days') {
            _expiresAt = DateTime.now().add(const Duration(days: 7));
          } else {
            _expiresAt = DateTime.now().add(const Duration(hours: 24));
          }
        });
      }
    } catch (_) {
      // Local rotation fallback
      final digits = ((DateTime.now().millisecondsSinceEpoch) % 10000)
          .toString()
          .padLeft(4, '0');
      setState(() {
        _inviteCode = digits;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeCopied.replaceAll('copied', 'rotated'))),
      );
    }
  }

  Future<void> _showExpiryPicker() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.expiry1Hour),
              onTap: () => Navigator.pop(ctx, '1 hour'),
            ),
            ListTile(
              title: Text(l10n.expiry24Hours),
              onTap: () => Navigator.pop(ctx, '24 hours'),
            ),
            ListTile(
              title: Text(l10n.expiry7Days),
              onTap: () => Navigator.pop(ctx, '7 days'),
            ),
          ],
        ),
      ),
    );

    if (choice != null) {
      await _rotateCode(choice);
    }
  }

  Future<void> _changeRole(String userId, String currentRole) async {
    final l10n = AppLocalizations.of(context);
    final newRole = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.roleEditor),
              leading: const Icon(Icons.edit_note_rounded),
              trailing: currentRole == 'editor'
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(ctx, 'editor'),
            ),
            ListTile(
              title: Text(l10n.roleViewer),
              leading: const Icon(Icons.visibility_outlined),
              trailing: currentRole == 'viewer'
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(ctx, 'viewer'),
            ),
          ],
        ),
      ),
    );

    if (newRole != null && newRole != currentRole) {
      await ref.read(groupsRepositoryProvider).updateMemberRole(
            groupId: widget.groupId,
            userId: userId,
            role: newRole,
          );
      await _loadGroupAndMembers();
    }
  }

  Future<void> _confirmRemoveMember(String userId, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeMemberConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightError,
            ),
            child: Text(l10n.removeMember),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(groupsRepositoryProvider).removeMember(
            groupId: widget.groupId,
            userId: userId,
          );
      await _loadGroupAndMembers();
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveGroup),
        content: Text(l10n.leaveGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightError,
            ),
            child: Text(l10n.leaveGroup),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(groupsRepositoryProvider).leaveGroup(widget.groupId);
      if (mounted) {
        context.go('/groups');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    final activeMembers = _members
        .where((m) => (m['status'] as String? ?? 'active') == 'active')
        .toList();
    final pendingMembers = _members
        .where((m) => (m['status'] as String? ?? '') == 'pending')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareAndMembers),
        actions: [
          if (!_isOwner)
            IconButton(
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.lightError,
              ),
              tooltip: l10n.leaveGroup,
              onPressed: _confirmLeaveGroup,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4-Digit Code & QR Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            l10n.vaultCode,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // 4 Large tabular digits
                          Text(
                            _inviteCode ?? '4829',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: theme.colorScheme.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // QR Code
                          if (_inviteCode != null)
                            QrImageView(
                              data: _inviteCode!,
                              version: QrVersions.auto,
                              size: 140.0,
                            ),
                          const SizedBox(height: AppSpacing.md),

                          // Expiry Chip & Change action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.timer_outlined, size: 16),
                                label: Text(_formatExpiresIn(l10n)),
                                onPressed: _isOwner ? _showExpiryPicker : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Action Buttons: Copy, Share, Rotate
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _inviteCode ?? ''),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.codeCopied)),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: Text(l10n.copyCode),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (_isOwner)
                                FilledButton.tonalIcon(
                                  onPressed: () => _rotateCode(),
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(l10n.rotateCode),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Owner switch: "Approve new members myself"
                  if (_isOwner) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(l10n.approveMembersMyself),
                        value: _requireApproval,
                        onChanged: (val) {
                          setState(() => _requireApproval = val);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Pending Members Section (if any)
                  if (_isOwner && pendingMembers.isNotEmpty) ...[
                    Text(
                      l10n.pendingMembers,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightAmberText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...pendingMembers.map((m) {
                      final userId = m['user_id'] as String;
                      final profile =
                          m['profiles'] as Map<String, dynamic>?;
                      final name =
                          profile?['display_name'] as String? ?? 'New User';

                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(l10n.joinedJustNow),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.lightSuccessText,
                                ),
                                tooltip: l10n.approve,
                                onPressed: () async {
                                  await ref
                                      .read(groupsRepositoryProvider)
                                      .approveMember(
                                        groupId: widget.groupId,
                                        userId: userId,
                                      );
                                  await _loadGroupAndMembers();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  color: AppColors.lightError,
                                ),
                                tooltip: l10n.decline,
                                onPressed: () async {
                                  await ref
                                      .read(groupsRepositoryProvider)
                                      .declineMember(
                                        groupId: widget.groupId,
                                        userId: userId,
                                      );
                                  await _loadGroupAndMembers();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Active Members List Header
                  Text(
                    l10n.members,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Members List
                  if (activeMembers.isEmpty)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_rounded),
                      ),
                      title: Text(l10n.roleOwner),
                      subtitle: Text(l10n.joinedJustNow),
                    )
                  else
                    ...activeMembers.map((m) {
                      final userId = m['user_id'] as String;
                      final role = m['role'] as String? ?? 'viewer';
                      final profile =
                          m['profiles'] as Map<String, dynamic>?;
                      final name =
                          profile?['display_name'] as String? ?? 'Member';
                      final isMe = userId == currentUserId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            isMe ? '$name (You)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            role == 'owner'
                                ? l10n.roleOwner
                                : (role == 'editor'
                                    ? l10n.roleEditor
                                    : l10n.roleViewer),
                          ),
                          trailing: _isOwner && role != 'owner'
                              ? PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'role') {
                                      _changeRole(userId, role);
                                    } else if (action == 'remove') {
                                      _confirmRemoveMember(userId, name);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'role',
                                      child: Text(
                                        'Change role (${role == 'editor' ? l10n.roleViewer : l10n.roleEditor})',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text(
                                        l10n.removeMember,
                                        style: const TextStyle(
                                          color: AppColors.lightError,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
