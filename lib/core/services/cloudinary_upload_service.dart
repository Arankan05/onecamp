import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadService {
  // Configured via --dart-define or defaults for development
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'onecamp-demo',
  );

  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'onecamp_unsigned',
  );

  final ImagePicker _picker;
  final http.Client _httpClient;

  CloudinaryUploadService({
    ImagePicker? picker,
    http.Client? httpClient,
  })  : _picker = picker ?? ImagePicker(),
        _httpClient = httpClient ?? http.Client();

  /// Pick an image from Camera or Gallery.
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return file;
    } catch (e) {
      throw Exception('Failed to select image: $e');
    }
  }

  /// Upload an XFile to Cloudinary using an unsigned upload preset.
  /// Returns the secure HTTPS image URL returned by Cloudinary.
  Future<String> uploadImage(XFile imageFile) async {
    final File file = File(imageFile.path);

    if (!await file.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    // Validate maximum file size (10 MB)
    final int fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('Image size exceeds maximum limit of 10MB.');
    }

    final Uri uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final http.StreamedResponse streamedResponse = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 30));

      final http.Response response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        } else {
          throw Exception('Cloudinary response did not contain a valid image URL.');
        }
      } else {
        final Map<String, dynamic>? errorJson =
            jsonDecode(response.body) as Map<String, dynamic>?;
        final String errorMsg = errorJson?['error']?['message'] ?? 'Status ${response.statusCode}';
        throw Exception('Cloudinary Upload Error: $errorMsg');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
