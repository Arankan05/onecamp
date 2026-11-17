import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'o5k43wz7';
  static const String _uploadPreset = 'onecamp_profile_images';

  Future<String> uploadProfileImage(XFile image) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'profiles';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'] as String;
    }

    throw Exception('Cloudinary upload failed: $responseBody');
  }
}
