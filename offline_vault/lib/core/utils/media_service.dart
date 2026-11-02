import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/compression_quality.dart';

class MediaService {
  /// Generate a 400px WebP thumbnail from an image file
  static Future<Uint8List> generateThumbnail(File sourceFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      sourceFile.absolute.path,
      minWidth: 400,
      minHeight: 400,
      quality: 80,
      format: CompressFormat.webp,
    );
    if (result == null) {
      throw Exception('Failed to generate thumbnail for ${sourceFile.path}');
    }
    return result;
  }

  /// Compress an image file according to the chosen quality preset
  static Future<File> compressImage({
    required File sourceFile,
    required CompressionQuality quality,
  }) async {
    if (quality == CompressionQuality.original || quality.maxDimension == null) {
      return sourceFile;
    }

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourceFile.path)}',
    );

    final compressedXFile = await FlutterImageCompress.compressAndGetFile(
      sourceFile.absolute.path,
      targetPath,
      minWidth: quality.maxDimension!,
      minHeight: quality.maxDimension!,
      quality: quality.jpegQuality,
      format: CompressFormat.jpeg,
    );

    if (compressedXFile == null) {
      return sourceFile;
    }

    return File(compressedXFile.path);
  }
}
