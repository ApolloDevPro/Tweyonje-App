import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_endpoints.dart';
import 'logger.dart';

/// Hybrid file upload service
/// - Uses Supabase Storage for file uploads
/// - Falls back to Django backend if needed
class HybridFileUploadService {
  final SupabaseClient _supabase;
  final String _storageBucket = 'tweyonje-uploads';

  HybridFileUploadService(this._supabase);

  /// Upload file to Supabase Storage
  Future<String?> uploadToSupabase({
    required File file,
    required String path,
    Map<String, String>? metadata,
  }) async {
    try {
      Logger.info('Uploading file to Supabase: $path');

      final fileBytes = await file.readAsBytes();
      final fileName = path.split('/').last;

      await _supabase.storage.from(_storageBucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileName),
              upsert: true,
            ),
          );

      // Get public URL
      final url = _supabase.storage.from(_storageBucket).getPublicUrl(path);

      Logger.info('File uploaded to Supabase: $url');
      return url;
    } catch (e) {
      Logger.error('Supabase upload failed', error: e);
      return null;
    }
  }

  /// Upload multiple files to Supabase Storage
  Future<List<String>> uploadMultipleToSupabase({
    required List<File> files,
    required String basePath,
    Map<String, String>? metadata,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;
      final path = '$basePath/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final url = await uploadToSupabase(file: file, path: path, metadata: metadata);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Delete file from Supabase Storage
  Future<bool> deleteFromSupabase(String path) async {
    try {
      Logger.info('Deleting file from Supabase: $path');
      await _supabase.storage.from(_storageBucket).remove([path]);
      Logger.info('File deleted from Supabase: $path');
      return true;
    } catch (e) {
      Logger.error('Supabase delete failed', error: e);
      return false;
    }
  }

  /// Get file URL from Supabase Storage
  String getSupabaseUrl(String path) {
    return _supabase.storage.from(_storageBucket).getPublicUrl(path);
  }

  /// List files in a directory
  Future<List<String>> listFiles(String directory) async {
    try {
      final files = await _supabase.storage.from(_storageBucket).list(path: directory);
      return files.map((file) => file.name).toList();
    } catch (e) {
      Logger.error('Failed to list files', error: e);
      return [];
    }
  }

  /// Upload to Django backend (fallback)
  Future<String?> uploadToBackend({
    required File file,
    required String path,
    String? token,
  }) async {
    try {
      Logger.info('Uploading file to Django backend: $path');

      // This would use the existing ApiClient
      // For now, return null to indicate fallback is needed
      Logger.warning('Django backend upload not implemented yet');
      return null;
    } catch (e) {
      Logger.error('Django backend upload failed', error: e);
      return null;
    }
  }

  /// Smart upload - tries Supabase first, falls back to Django
  Future<String?> smartUpload({
    required File file,
    required String path,
    String? token,
  }) async {
    // Try Supabase first
    final supabaseUrl = await uploadToSupabase(file: file, path: path);
    if (supabaseUrl != null) {
      return supabaseUrl;
    }

    // Fallback to Django backend
    return await uploadToBackend(file: file, path: path, token: token);
  }

  /// Get content type from file extension
  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}

final hybridFileUploadServiceProvider = Provider<HybridFileUploadService>((ref) {
  final supabase = Supabase.instance.client;
  return HybridFileUploadService(supabase);
});
