import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';

/// Service for uploading marketplace listing images to Cloudinary via HTTP REST API.
class CloudinaryService {
  /// Maximum permitted image file size (10 MB).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image file extensions.
  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'heic',
    'bmp',
  ];

  /// Validates image existence, extension, and file size before uploading.
  static void validateImageFile(File imageFile) {
    if (!kIsWeb && !imageFile.existsSync()) {
      throw Exception('Selected image file does not exist.');
    }

    if (!kIsWeb) {
      final fileSize = imageFile.lengthSync();
      if (fileSize > maxFileSizeBytes) {
        final mb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        throw Exception(
          'Image size ($mb MB) exceeds maximum allowed limit of 10 MB.',
        );
      }
    }

    final path = imageFile.path.toLowerCase();
    final hasValidExtension = allowedExtensions.any(
      (ext) => path.endsWith('.$ext'),
    );
    if (!hasValidExtension && !kIsWeb) {
      throw Exception(
        'Invalid image format. Supported formats: ${allowedExtensions.join(', ')}',
      );
    }
  }

  /// Uploads a single [XFile] to Cloudinary cross-platform (Web & Mobile).
  Future<String> uploadXFile(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    if (bytes.length > maxFileSizeBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw Exception(
        'Image size ($mb MB) exceeds maximum allowed limit of 10 MB.',
      );
    }

    final filename = xFile.name.isNotEmpty ? xFile.name : 'upload.jpg';
    final uri = Uri.parse(AppConstants.cloudinaryUploadUrl);

    final presetsToTry = [
      AppConstants.cloudinaryMarketplacePreset,
      'onecamp_chat_images',
      'onecamp_event_images',
    ];

    String lastErrorMessage = 'Unknown upload error.';

    for (final preset in presetsToTry) {
      try {
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = preset
          ..fields['folder'] = AppConstants.cloudinaryMarketplaceFolder
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          final secureUrl = jsonResponse['secure_url'] as String?;

          if (secureUrl != null && secureUrl.trim().isNotEmpty) {
            return secureUrl;
          }
        } else {
          final Map<String, dynamic>? jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>?;
          lastErrorMessage =
              jsonResponse?['error']?['message'] ??
              'Status ${response.statusCode}';
        }
      } catch (e) {
        lastErrorMessage = '$e';
      }
    }

    throw Exception('Cloudinary upload failed: $lastErrorMessage');
  }

  /// Uploads a single image to Cloudinary using unsigned HTTP REST endpoint.
  Future<String> uploadImage(File imageFile) async {
    if (kIsWeb) {
      return uploadXFile(XFile(imageFile.path));
    }

    validateImageFile(imageFile);
    return uploadXFile(XFile(imageFile.path));
  }

  /// Uploads a list of [XFile]s sequentially and returns their secure HTTPS URLs.
  Future<List<String>> uploadMultipleXFiles(List<XFile> xFiles) async {
    final List<String> uploadedUrls = [];
    for (final xFile in xFiles) {
      final url = await uploadXFile(xFile);
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  /// Uploads a list of image files sequentially and returns their secure HTTPS URLs.
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];
    for (final file in imageFiles) {
      final url = await uploadImage(file);
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }
}
