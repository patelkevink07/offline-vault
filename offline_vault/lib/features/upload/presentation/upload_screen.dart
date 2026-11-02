import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../../data/models/compression_quality.dart';
import '../../../data/repositories/upload_queue_repository.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({
    super.key,
    required this.groupId,
    this.folderId,
  });

  final String groupId;
  final String? folderId;

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final List<File> _selectedFiles = [];
  CompressionQuality _selectedQuality = CompressionQuality.high;
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(
          result.paths.whereType<String>().map((p) => File(p)),
        );
      });
    }
  }

  Future<void> _startUpload() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    final queueRepo = ref.read(uploadQueueRepositoryProvider);
    final keyManager = KeyManager();
    final crypto = CryptoService(keyManager: keyManager);
    final storage = FileStorageService(cryptoService: crypto);

    for (final file in _selectedFiles) {
      final name = file.path.split(Platform.pathSeparator).last;
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';

      final queueId = await queueRepo.enqueueFile(
        localPath: file.path,
        groupId: widget.groupId,
        folderId: widget.folderId,
        name: name,
        mime: mime,
      );

      // Process upload immediately
      final item = (await queueRepo.watchQueue(widget.groupId).first)
          .firstWhere((q) => q.id == queueId);

      await queueRepo.processQueueItem(
        item: item,
        storageService: storage,
        quality: _selectedQuality,
      );
    }

    if (mounted) {
      setState(() => _isUploading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Files'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action buttons to pick images/PDFs
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add Images'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickPdfs,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Add PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Compression quality selector
            Text(
              'Upload Quality',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<CompressionQuality>(
              segments: const [
                ButtonSegment(
                  value: CompressionQuality.original,
                  label: Text('Original'),
                ),
                ButtonSegment(
                  value: CompressionQuality.high,
                  label: Text('High'),
                ),
                ButtonSegment(
                  value: CompressionQuality.dataSaver,
                  label: Text('Saver'),
                ),
              ],
              selected: {_selectedQuality},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _selectedQuality = set.first);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Selected files list
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Text(
                        'No files selected yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final name = file.path.split(Platform.pathSeparator).last;
                        final isPdf = name.toLowerCase().endsWith('.pdf');

                        return ListTile(
                          leading: Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: isPdf ? AppColors.lightError : AppColors.lightPrimary,
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _isUploading
                                ? null
                                : () => setState(() => _selectedFiles.removeAt(index)),
                          ),
                        );
                      },
                    ),
            ),

            // Upload button
            FilledButton(
              onPressed: (_selectedFiles.isEmpty || _isUploading)
                  ? null
                  : _startUpload,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Upload ${_selectedFiles.length} files'),
            ),
          ],
        ),
      ),
    );
  }
}
