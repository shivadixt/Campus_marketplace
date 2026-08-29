import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_compressor.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // Upload listing photos
  Future<List<String>> uploadListingImages({
    required String listingId,
    required List<XFile> images,
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    if (images.isEmpty) {
      return [];
    }

    final List<String> downloadUrls = [];
    final int totalImages = images.length;

    for (int i = 0; i < totalImages; i++) {
      final rawFile = images[i];
      final int imageNumber = i + 1;

      if (onProgress != null) {
        final double compressionProgress = (i / totalImages) * 0.5;
        onProgress(compressionProgress, 'Compressing photo $imageNumber of $totalImages...');
      }

      final compressed = await ImageCompressor.compressImage(rawFile);

      if (onProgress != null) {
        final double uploadProgress = 0.5 + (i / totalImages) * 0.5;
        onProgress(uploadProgress, 'Uploading photo $imageNumber of $totalImages...');
      }

      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = _storage.ref().child('listings/$listingId/$fileName');

      final uploadTask = ref.putFile(
        File(compressed.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      downloadUrls.add(url);
    }

    if (onProgress != null) {
      onProgress(1.0, 'Upload complete');
    }

    return downloadUrls;
  }

  // Delete listing photos folder
  Future<void> deleteListingFolder(String listingId) async {
    try {
      final listResult = await _storage.ref().child('listings/$listingId').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Delete folder error: $e');
    }
  }
}
