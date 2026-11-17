import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadService {
  // Configured via --dart-define or defaults for development
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'o5k43wz7',
  );

  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'onecamp_chat_images',
  );

  static const List<String> _allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'gif',
  ];

  static const List<String> _allowedDocExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'csv',
  ];

  static const List<String> _allowedAudioExtensions = [
    'mp3',
    'm4a',
    'wav',
    'aac',
    'ogg',
  ];

  final String _preset;
  final ImagePicker _picker;
  final http.Client _httpClient;

  CloudinaryUploadService({
    String? uploadPreset,
    ImagePicker? picker,
    http.Client? httpClient,
  }) : _preset =
           uploadPreset ??
           (const String.fromEnvironment(
                 'CLOUDINARY_UPLOAD_PRESET',
                 defaultValue: '',
               ).isNotEmpty
               ? const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET')
               : 'onecamp_event_images'),
       _picker = picker ?? ImagePicker(),
       _httpClient = httpClient ?? http.Client();

  /// Pick an image from Camera or Gallery.
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (file != null) {
        _validateImageFile(file);
      }
      return file;
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw Exception('Failed to select image: $e');
    }
  }

  /// Validate image existence, file extension, and maximum size (10 MB).
  void _validateImageFile(XFile imageFile) {
    final path = imageFile.path.toLowerCase();
    final extension = path.contains('.') ? path.split('.').last : '';

    if (extension.isNotEmpty && !_allowedImageExtensions.contains(extension)) {
      throw ArgumentError(
        'Unsupported image format (.$extension). Please select a JPG, PNG, WEBP, or HEIC image.',
      );
    }
  }

  /// Validate document extension.
  void validateDocExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext.isNotEmpty && !_allowedDocExtensions.contains(ext)) {
      throw ArgumentError(
        'Unsupported document type (.$ext). Supported: PDF, DOC, DOCX, TXT, XLS, PPT, CSV.',
      );
    }
  }

  /// Validate audio extension.
  void validateAudioExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext.isNotEmpty && !_allowedAudioExtensions.contains(ext)) {
      throw ArgumentError(
        'Unsupported audio format (.$ext). Supported: MP3, M4A, WAV, AAC, OGG.',
      );
    }
  }

  /// Upload an XFile to Cloudinary using an unsigned upload preset.
  /// Accepts optional [customPublicId] to ensure idempotent asset creation on retries.
  Future<String> uploadImage(XFile imageFile, {String? customPublicId}) async {
    final File file = File(imageFile.path);

    if (!await file.exists()) {
      throw Exception('Selected image file does not exist on device.');
    }

    _validateImageFile(imageFile);

    // Validate maximum file size (10 MB)
    final int fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('Image size exceeds maximum limit of 10MB.');
    }

    return uploadFile(
      file: file,
      resourceType: 'image',
      customPublicId: customPublicId,
      maxSizeBytes: 10 * 1024 * 1024,
    );
  }

  /// Generic file upload (documents, audio, video) to Cloudinary.
  Future<String> uploadFile({
    required File file,
    String resourceType = 'auto',
    String? customPublicId,
    int maxSizeBytes = 20 * 1024 * 1024, // 20 MB max
  }) async {
    if (!await file.exists()) {
      throw Exception('Selected file does not exist on device.');
    }

    final int fileSize = await file.length();
    if (fileSize > maxSizeBytes) {
      final double mb = maxSizeBytes / (1024 * 1024);
      throw Exception(
        'File size exceeds maximum limit of ${mb.toStringAsFixed(0)}MB.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _preset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    if (customPublicId != null && customPublicId.isNotEmpty) {
      request.fields['public_id'] = customPublicId;
    }

    try {
      final http.StreamedResponse streamedResponse = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 45));

      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        } else {
          throw Exception('Cloudinary response did not contain a valid URL.');
        }
      } else {
        final Map<String, dynamic>? errorJson =
            jsonDecode(response.body) as Map<String, dynamic>?;
        final String rawErrorMsg =
            (errorJson?['error']?['message'] as String? ?? '').toLowerCase();

        if (customPublicId != null &&
            customPublicId.isNotEmpty &&
            (rawErrorMsg.contains('already exists') ||
                rawErrorMsg.contains('already present') ||
                rawErrorMsg.contains('already in use'))) {
          final String fallbackUrl =
              'https://res.cloudinary.com/$_cloudName/$resourceType/upload/$customPublicId';

          try {
            final http.Response headResponse = await _httpClient
                .head(Uri.parse(fallbackUrl))
                .timeout(const Duration(seconds: 5));

            if (headResponse.statusCode == 200) {
              return fallbackUrl;
            }
          } catch (_) {}
        }

        final String displayErrorMsg =
            errorJson?['error']?['message'] ?? 'Status ${response.statusCode}';
        throw Exception('Cloudinary Upload Error: $displayErrorMsg');
      }
    } on TimeoutException {
      throw Exception(
        'Network timeout while uploading file. Please check connection and retry.',
      );
    } on SocketException {
      throw Exception('No network connection. Please reconnect and retry.');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}
