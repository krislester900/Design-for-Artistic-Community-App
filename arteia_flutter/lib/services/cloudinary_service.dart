import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._();
  factory CloudinaryService() => _instance;
  CloudinaryService._();

  late final String _cloudName;
  late final String _uploadPreset;

  Future<void> initialize() async {
    _cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'leyyabsn');
    _uploadPreset = const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'Kris_ndri');

    if (kDebugMode) {
      debugPrint('☁️ Cloudinary initialized: cloud=$_cloudName, preset=$_uploadPreset');
    }
  }

  Future<String?> uploadImage(File imageFile, {String folder = 'artworks'}) async {
    try {
      if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
        throw Exception('Cloudinary configuration missing');
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      debugPrint('📤 Uploading to Cloudinary: ${imageFile.path}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);

      if (response.statusCode == 200 && json['secure_url'] != null) {
        final url = json['secure_url'] as String;
        debugPrint('✅ Cloudinary upload success: $url');
        return url;
      } else {
        throw Exception(json['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return false;

      final publicId = _extractPublicId(imageUrl);
      if (publicId.isEmpty) return false;

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'public_id': publicId,
          'upload_preset': _uploadPreset,
        }),
      );

      debugPrint('🗑️ Cloudinary delete: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Cloudinary delete error: $e');
      return false;
    }
  }

  String _extractPublicId(String url) {
    try {
      final regex = RegExp(r'/v\d+/.+/(.+)\.\w+$');
      final match = regex.firstMatch(url);
      if (match != null) {
        return match.group(1) ?? '';
      }

      final parts = url.split('/');
      if (parts.length > 2) {
        final fileName = parts.last.split('.').first;
        return fileName;
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}