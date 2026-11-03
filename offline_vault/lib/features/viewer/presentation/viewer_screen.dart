import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/crypto/crypto_service.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../../data/local/database.dart';
import '../../../sync/sync_engine.dart';

class FileViewerScreen extends ConsumerStatefulWidget {
  const FileViewerScreen({
    super.key,
    required this.fileId,
    required this.groupId,
  });

  final String fileId;
  final String groupId;

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> {
  LocalFile? _file;
  Uint8List? _decryptedImageBytes;
  PdfDocument? _pdfDocument;
  PdfController? _pdfController;
  String? _tempPdfPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _pdfDocument?.close();
    if (_tempPdfPath != null) {
      File(_tempPdfPath!).delete().ignore();
    }
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    var file = await db.filesDao.getById(widget.fileId);

    if (file == null) {
      setState(() {
        _errorMessage = 'File not found in local database';
        _isLoading = false;
      });
      return;
    }

    _file = file;
    var path = file.localOriginalPath ?? file.localThumbPath;

    // Download on demand if not yet on local storage
    if (path == null || !File(path).existsSync()) {
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.downloadFile(file);
      file = await db.filesDao.getById(widget.fileId);
      if (file != null) {
        _file = file;
        path = file.localOriginalPath ?? file.localThumbPath;
      }
    }

    if (path == null || !File(path).existsSync()) {
      setState(() {
        _errorMessage = 'File not yet downloaded to this device. Please connect to internet to download.';
        _isLoading = false;
      });
      return;
    }

    try {
      final keyManager = KeyManager();
      final crypto = CryptoService(keyManager: keyManager);
      final storage = FileStorageService(cryptoService: crypto);

      if (file!.mime.startsWith('image/')) {
        final decrypted = await storage.readDecryptedFile(path);
        setState(() {
          _decryptedImageBytes = decrypted;
          _isLoading = false;
        });
      } else if (file.mime == 'application/pdf') {
        final tempPath = await storage.createTempDecryptedFile(
          sourceEncryptedPath: path,
          fileName: 'view_${file.id}.pdf',
        );
        _tempPdfPath = tempPath;
        final doc = await PdfDocument.openFile(tempPath);
        setState(() {
          _pdfDocument = doc;
          _pdfController = PdfController(
            document: PdfDocument.openFile(tempPath),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to decrypt and render file: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _file?.name ?? 'Viewer',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _file != null ? _showInfoSheet : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _decryptedImageBytes != null
                  ? PhotoViewGallery.builder(
                      itemCount: 1,
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: MemoryImage(_decryptedImageBytes!),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 3,
                        );
                      },
                    )
                  : _pdfController != null
                      ? PdfView(
                          controller: _pdfController!,
                          scrollDirection: Axis.vertical,
                        )
                      : const SizedBox.shrink(),
    );
  }

  void _showInfoSheet() {
    if (_file == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _file!.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Size: ${(_file!.size / (1024 * 1024)).toStringAsFixed(2)} MB'),
            Text('Type: ${_file!.mime}'),
            Text('Sync state: ${_file!.originalState}'),
            if (_file!.note != null) ...[
              const SizedBox(height: 8),
              Text('Note: ${_file!.note!}'),
            ],
          ],
        ),
      ),
    );
  }
}
