import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
    if (!imageFile.existsSync()) {
      throw Exception('Selected image file does not exist.');
    }

    final fileSize = imageFile.lengthSync();
    if (fileSize > maxFileSizeBytes) {
      final mb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw Exception(
        'Image size ($mb MB) exceeds maximum allowed limit of 10 MB.',
      );
    }

    final path = imageFile.path.toLowerCase();
    final hasValidExtension = allowedExtensions.any(
      (ext) => path.endsWith('.$ext'),
    );
    if (!hasValidExtension) {
      throw Exception(
        'Invalid image format. Supported formats: ${allowedExtensions.join(', ')}',
      );
    }
  }

  /// Uploads a single image to Cloudinary using unsigned HTTP REST endpoint.
  /// Returns the secure HTTPS URL of the uploaded image asset.
  Future<String> uploadImage(File imageFile) async {
    validateImageFile(imageFile);

    try {
      final uri = Uri.parse(AppConstants.cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConstants.cloudinaryMarketplacePreset
        ..fields['folder'] = AppConstants.cloudinaryMarketplaceFolder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = jsonResponse['secure_url'] as String?;

        if (secureUrl == null || secureUrl.trim().isEmpty) {
          throw Exception(
            'Cloudinary upload response did not contain a secure_url.',
          );
        }

        final parsedUri = Uri.tryParse(secureUrl);
        final isValidHttpsUrl =
            parsedUri != null &&
            parsedUri.isAbsolute &&
            parsedUri.scheme == 'https' &&
            parsedUri.host.isNotEmpty;

        if (!isValidHttpsUrl) {
          throw Exception(
            'Cloudinary upload response returned an invalid HTTPS URL: $secureUrl',
          );
        }

        return secureUrl;
      } else {
        final Map<String, dynamic>? jsonResponse =
            jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            jsonResponse?['error']?['message'] ??
            'HTTP ${response.statusCode} upload error.';
        throw Exception('Cloudinary upload failed: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
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
