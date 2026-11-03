import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/crypto_service.dart';

/// App-private encrypted file storage service.
class FileStorageService {
  FileStorageService({required CryptoService cryptoService})
      : _cryptoService = cryptoService;

  final CryptoService _cryptoService;
  Directory? _appDir;

  Future<Directory> get appDir async {
    _appDir ??= await getApplicationDocumentsDirectory();
    return _appDir!;
  }

  Future<String> getGroupDir(String groupId) async {
    final root = await appDir;
    final dir = Directory(p.join(root.path, 'vault', groupId));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String> getOriginalsPath(String groupId) async {
    final groupDir = await getGroupDir(groupId);
    final dir = Directory(p.join(groupDir, 'originals'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String> getThumbsPath(String groupId) async {
    final groupDir = await getGroupDir(groupId);
    final dir = Directory(p.join(groupDir, 'thumbs'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Write plaintext bytes after encrypting them with AES-GCM.
  Future<String> writeEncryptedFile({
    required String filePath,
    required Uint8List plainBytes,
  }) async {
    final encrypted = await _cryptoService.encrypt(plainBytes);
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(encrypted, flush: true);
    return file.path;
  }

  /// Read and decrypt an encrypted file from disk.
  Future<Uint8List> readDecryptedFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }
    final cipherBytes = await file.readAsBytes();
    return _cryptoService.decrypt(cipherBytes);
  }

  /// Delete a file if it exists.
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Purge all files for a specific group (e.g. member removed or group deleted).
  Future<void> purgeGroup(String groupId) async {
    final root = await appDir;
    final dir = Directory(p.join(root.path, 'vault', groupId));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Clear any leftover decrypted temporary files in app cache.
  Future<void> cleanTempFiles() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final tempVaultDir = Directory(p.join(cacheDir.path, 'vault_temp'));
      if (tempVaultDir.existsSync()) {
        await tempVaultDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Wipe all files and thumbnails for a group from the device.
  Future<void> wipeGroupStorage(String groupId) async {
    try {
      final root = await appDir;
      final dir = Directory(p.join(root.path, 'vault', groupId));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Create a temporary decrypted file (e.g. for PDF viewer), returning the path.
  Future<String> createTempDecryptedFile({
    required String sourceEncryptedPath,
    required String fileName,
  }) async {
    final cacheDir = await getTemporaryDirectory();
    final tempDir = Directory(p.join(cacheDir.path, 'vault_temp'));
    if (!tempDir.existsSync()) {
      await tempDir.create(recursive: true);
    }
    final decryptedBytes = await readDecryptedFile(sourceEncryptedPath);
    final tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(decryptedBytes, flush: true);
    return tempFile.path;
  }
}

/// Riverpod provider for a shared [FileStorageService] instance.
final fileStorageProvider = Provider<FileStorageService>((ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  return FileStorageService(cryptoService: crypto);
});
