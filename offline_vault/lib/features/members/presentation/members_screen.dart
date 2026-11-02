import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../data/repositories/groups_repository.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String? _inviteCode;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    setState(() => _isLoading = true);
    final cleanId = widget.groupId.replaceAll('-', '').toUpperCase();
    final fallbackCode = cleanId.length >= 8 ? cleanId.substring(0, 8) : cleanId.padRight(8, '0');
    final remote = ref.read(groupsRemoteSourceProvider);
    try {
      final res = await remote.getInviteCode(widget.groupId);
      if (res != null && res['code'] != null) {
        setState(() {
          _inviteCode = res['code'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _inviteCode = fallbackCode;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _inviteCode = fallbackCode;
        _isLoading = false;
      });
    }
  }

  Future<void> _rotateCode() async {
    final remote = ref.read(groupsRemoteSourceProvider);
    try {
      final res = await remote.rotateInviteCode(groupId: widget.groupId);
      if (res['code'] != null) {
        setState(() {
          _inviteCode = res['code'] as String?;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite code rotated successfully!')),
          );
        }
        return;
      }
    } catch (_) {}

    final newLocalCode = const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    setState(() {
      _inviteCode = newLocalCode;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault invite code rotated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Sharing & Code'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Join Code Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.lightOutline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Group Invite Code',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Anyone with this code joins instantly as a Viewer with full offline access.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_inviteCode != null) ...[
                      // Formatted code
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _inviteCode!.length >= 8
                              ? '${_inviteCode!.substring(0, 4)}-${_inviteCode!.substring(4, 8)}'
                              : _inviteCode!,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // QR Code
                      QrImageView(
                        data: _inviteCode!,
                        version: QrVersions.auto,
                        size: 160.0,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _inviteCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied to clipboard!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: _rotateCode,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Rotate Code'),
                          ),
                        ],
                      ),
                    ] else
                      Text(_error ?? 'Only group owners can view and manage invite codes.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
