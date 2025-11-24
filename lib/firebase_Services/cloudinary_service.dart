import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary credentials
  final String cloudName = "dq0onjs4l";
  final String uploadPreset = "mechat_unsigned";

  /// Upload image by file path
  Future<String?> uploadImage(String filePath) async {
    return await _uploadFile(filePath, 'image');
  }

  /// Upload video by file path
  Future<String?> uploadVideo(String filePath) async {
    return await _uploadFile(filePath, 'video');
  }

  /// Upload audio by file path
  Future<String?> uploadAudio(String filePath) async {
    return await _uploadFile(filePath, 'video'); // Cloudinary treats audio as video
  }

  /// Upload document/file by file path
  Future<String?> uploadFile(String filePath) async {
    return await _uploadFile(filePath, 'raw');
  }

  /// Generic upload method
  Future<String?> _uploadFile(String filePath, String resourceType) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (streamed.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final String fileUrl = data['secure_url'] as String;
        return fileUrl;
      } else {
        // Upload failed
        return null;
      }
    } catch (e) {
      // Cloudinary upload error
      return null;
    }
  }

  /// Wrapper that accepts a File for images
  Future<String?> uploadImageToCloudinary(File file) async {
    if (file.path.isEmpty) return null;
    return await uploadImage(file.path);
  }

  /// Wrapper that accepts a File for videos
  Future<String?> uploadVideoToCloudinary(File file) async {
    if (file.path.isEmpty) return null;
    return await uploadVideo(file.path);
  }

  /// Wrapper that accepts a File for audio
  Future<String?> uploadAudioToCloudinary(File file) async {
    if (file.path.isEmpty) return null;
    return await uploadAudio(file.path);
  }

  /// Wrapper that accepts a File for documents
  Future<String?> uploadFileToCloudinary(File file) async {
    if (file.path.isEmpty) return null;
    return await uploadFile(file.path);
  }
}
