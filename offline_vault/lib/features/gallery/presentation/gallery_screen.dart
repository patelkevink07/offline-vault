import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/folders_repository.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({
    super.key,
    required this.groupId,
    this.folderId,
  });

  final String groupId;
  final String? folderId;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);
    final foldersRepo = ref.watch(foldersRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search files...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (q) => setState(() => _searchQuery = q.trim()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            onPressed: () => context.push('/group/${widget.groupId}/members'),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showCreateFolderDialog(context, foldersRepo),
          ),
        ],
      ),
      body: StreamBuilder<List<LocalFolder>>(
        stream: foldersRepo.watchFolders(widget.groupId, parentId: widget.folderId),
        builder: (context, folderSnapshot) {
          final folders = folderSnapshot.data ?? [];

          return StreamBuilder<List<LocalFile>>(
            stream: _searchQuery.isEmpty
                ? db.filesDao.watchByGroup(widget.groupId, folderId: widget.folderId)
                : Stream.fromFuture(db.filesDao.search(_searchQuery)),
            builder: (context, fileSnapshot) {
              final files = fileSnapshot.data ?? [];

              if (folders.isEmpty && files.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'This vault folder is empty',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap the + button below to add photos or documents',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // Folders list if any
                  if (folders.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 52,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          scrollDirection: Axis.horizontal,
                          itemCount: folders.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return ActionChip(
                              avatar: const Icon(Icons.folder_rounded, size: 18),
                              label: Text(folder.name),
                              onPressed: () => context.push('/group/${widget.groupId}/folder/${folder.id}'),
                            );
                          },
                        ),
                      ),
                    ),

                  // Files grid
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final file = files[index];
                          return _buildThumbnailTile(file);
                        },
                        childCount: files.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/group/${widget.groupId}/upload'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildThumbnailTile(LocalFile file) {
    final hasThumb = file.localThumbPath != null && File(file.localThumbPath!).existsSync();
    final isPdf = file.mime == 'application/pdf';

    return InkWell(
      onTap: () => context.push('/viewer/${file.id}?groupId=${widget.groupId}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightOutline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightOutline, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumb)
              FutureBuilder(
                future: _decryptThumb(file.localThumbPath!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)));
                },
              )
            else
              Center(
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.image_outlined,
                  size: 32,
                  color: isPdf ? AppColors.lightError : AppColors.lightPrimary,
                ),
              ),

            // Badge in corner for ready state
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  file.originalState == 'ready' ? Icons.check_circle : Icons.cloud_download_outlined,
                  size: 14,
                  color: file.originalState == 'ready' ? AppColors.success : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _decryptThumb(String path) async {
    final keyManager = KeyManager();
    final crypto = CryptoService(keyManager: keyManager);
    final storage = FileStorageService(cryptoService: crypto);
    return storage.readDecryptedFile(path);
  }

  void _showCreateFolderDialog(BuildContext context, FoldersRepository repo) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await repo.createFolder(
                  groupId: widget.groupId,
                  parentId: widget.folderId,
                  name: name,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
