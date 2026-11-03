import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

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

class _UploadFileItem {
  _UploadFileItem({
    required this.file,
    required this.nameController,
    required this.isPdf,
  });

  final File file;
  final TextEditingController nameController;
  final bool isPdf;
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final List<_UploadFileItem> _selectedItems = [];
  CompressionQuality _selectedQuality = CompressionQuality.high;
  bool _isUploading = false;

  @override
  void dispose() {
    for (final item in _selectedItems) {
      item.nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        for (final x in picked) {
          final defaultName = x.name.isNotEmpty
              ? x.name
              : x.path.split(Platform.pathSeparator).last;
          _selectedItems.add(
            _UploadFileItem(
              file: File(x.path),
              nameController: TextEditingController(text: defaultName),
              isPdf: false,
            ),
          );
        }
      });
    }
  }

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final f in result.files) {
          if (f.path != null) {
            _selectedItems.add(
              _UploadFileItem(
                file: File(f.path!),
                nameController: TextEditingController(text: f.name),
                isPdf: true,
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _startUpload() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final queueRepo = ref.read(uploadQueueRepositoryProvider);
      final storage = ref.read(fileStorageProvider);

      for (final item in _selectedItems) {
        String customName = item.nameController.text.trim();
        if (customName.isEmpty) {
          customName = item.file.path.split(Platform.pathSeparator).last;
        }
        final mime = lookupMimeType(item.file.path) ??
            (item.isPdf ? 'application/pdf' : 'application/octet-stream');

        await queueRepo.enqueueAndProcessFile(
          localPath: item.file.path,
          groupId: widget.groupId,
          folderId: widget.folderId,
          name: customName,
          mime: mime,
          storageService: storage,
          quality: _selectedQuality,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Files saved and encrypted in vault!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Files & Documents'),
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
                    label: const Text('Add Document'),
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

            // Selected files list with document naming fields
            Expanded(
              child: _selectedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No documents selected yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Tap "Add Images" or "Add Document" above.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _selectedItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        int fileSizeBytes = 0;
                        try {
                          fileSizeBytes = item.file.lengthSync();
                        } catch (_) {}
                        final sizeKb = (fileSizeBytes / 1024).toStringAsFixed(1);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.lightOutline, width: 0.8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item.isPdf
                                        ? AppColors.lightError.withValues(alpha: 0.1)
                                        : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.isPdf ? Icons.picture_as_pdf : Icons.image,
                                    color: item.isPdf ? AppColors.lightError : theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: item.nameController,
                                        enabled: !_isUploading,
                                        decoration: const InputDecoration(
                                          labelText: 'Document Name',
                                          isDense: true,
                                          border: UnderlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$sizeKb KB • ${item.isPdf ? "PDF Document" : "Image"}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'Remove',
                                  onPressed: _isUploading
                                      ? null
                                      : () => setState(() {
                                          item.nameController.dispose();
                                          _selectedItems.removeAt(index);
                                        }),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Upload button
            FilledButton(
              onPressed: (_selectedItems.isEmpty || _isUploading)
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
                  : Text('Upload ${_selectedItems.length} File${_selectedItems.length == 1 ? "" : "s"}'),
            ),
          ],
        ),
      ),
    );
  }
}
