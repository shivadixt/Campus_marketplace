import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/image_compressor.dart';

class StorageService {
  StorageService();

  // Upload single photo
  Future<String> uploadImageToCloudinary({
    required XFile imageFile,
    String folder = 'campus_marketplace',
  }) async {
    final compressed = await ImageCompressor.compressImage(imageFile);

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
    request.fields['folder'] = folder;

    final multipartFile = await http.MultipartFile.fromPath('file', compressed.path);
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      String secureUrl = '';
      if (responseData['secure_url'] != null) {
        secureUrl = responseData['secure_url'].toString();
      }
      return secureUrl;
    } else {
      debugPrint('Upload error (${response.statusCode}): ${response.body}');
      throw Exception('Failed to upload image');
    }
  }

  // Upload multiple listing photos
  Future<List<String>> uploadListingImages({
    required String listingId,
    required List<XFile> images,
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    if (images.isEmpty) {
      return [];
    }

    final List<String> uploadedUrls = [];
    final int totalImages = images.length;

    for (int i = 0; i < totalImages; i++) {
      final rawFile = images[i];
      final int imageNumber = i + 1;

      if (onProgress != null) {
        final double progressValue = (i / totalImages);
        onProgress(progressValue, 'Uploading photo $imageNumber of $totalImages...');
      }

      final uploadedUrl = await uploadImageToCloudinary(
        imageFile: rawFile,
        folder: 'campus_marketplace/listings/$listingId',
      );

      if (uploadedUrl.isNotEmpty) {
        uploadedUrls.add(uploadedUrl);
      }
    }

    if (onProgress != null) {
      onProgress(1.0, 'Saving listing details...');
    }

    return uploadedUrls;
  }

  // Delete listing folder (placeholder)
  Future<void> deleteListingFolder(String listingId) async {
  }
}
