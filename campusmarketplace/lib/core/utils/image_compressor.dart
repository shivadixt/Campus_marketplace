import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

class ImageCompressor {
  ImageCompressor._();

  // Compress single image
  static Future<XFile> compressImage(XFile file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: AppConstants.maxImageDimension,
        minHeight: AppConstants.maxImageDimension,
        quality: AppConstants.imageCompressionQuality,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return XFile(result.path);
      }
      return file;
    } catch (e) {
      debugPrint('Compression notice: $e');
      return file;
    }
  }

  // Compress multiple images
  static Future<List<XFile>> compressMultiple(List<XFile> files) async {
    final List<XFile> compressedList = [];
    for (final file in files) {
      final compressed = await compressImage(file);
      compressedList.add(compressed);
    }
    return compressedList;
  }
}
