import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../../data/local/database.dart';
import '../../../data/remote/supabase_client.dart';
import '../../../data/repositories/groups_repository.dart';
import '../../../data/repositories/upload_queue_repository.dart';
import '../../../sync/sync_engine.dart';

class SyncCentreScreen extends ConsumerStatefulWidget {
  const SyncCentreScreen({super.key});

  @override
  ConsumerState<SyncCentreScreen> createState() => _SyncCentreScreenState();
}

class _SyncCentreScreenState extends ConsumerState<SyncCentreScreen> {
  bool _isSyncing = false;

  Future<void> _triggerManualSync() async {
    setState(() => _isSyncing = true);
    final db = ref.read(databaseProvider);
    final supabase = ref.read(supabaseClientProvider);
    final remote = ref.read(groupsRemoteSourceProvider);
    final uploadQueue = ref.read(uploadQueueRepositoryProvider);
    final keyManager = KeyManager();
    final crypto = CryptoService(keyManager: keyManager);
    final storage = FileStorageService(cryptoService: crypto);
    final connectivity = ref.read(connectivityServiceProvider);

    final engine = SyncEngine(
      db: db,
      supabase: supabase,
      remoteSource: remote,
      uploadQueueRepo: uploadQueue,
      storageService: storage,
      connectivity: connectivity,
    );

    await engine.run(trigger: SyncTrigger.manual);

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Centre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.lightOutline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSyncing ? 'Syncing...' : 'Ready for Sync',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Local database guarantees offline access',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sync Now Action
            FilledButton.icon(
              onPressed: _isSyncing ? null : _triggerManualSync,
              icon: _isSyncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync_rounded),
              label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Upload Queue',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            Expanded(
              child: StreamBuilder<List<UploadQueueData>>(
                stream: db.uploadQueueDao.watchPending(),
                builder: (context, snapshot) {
                  final queue = snapshot.data ?? [];
                  if (queue.isEmpty) {
                    return Center(
                      child: Text(
                        'No pending uploads.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: queue.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      return ListTile(
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: Text(item.name),
                        subtitle: Text('Status: ${item.state} • Attempts: ${item.attempts}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
