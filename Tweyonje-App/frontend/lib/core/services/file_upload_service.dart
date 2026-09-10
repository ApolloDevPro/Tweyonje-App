import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'error_handler.dart';
import 'logger.dart';

enum UploadType {
  wasteRequestPhoto,
  profilePhoto,
  evidencePhoto,
  document,
}

class UploadProgress {
  final String fileId;
  final double progress;
  final UploadStatus status;
  final String? errorMessage;

  UploadProgress({
    required this.fileId,
    this.progress = 0.0,
    this.status = UploadStatus.pending,
    this.errorMessage,
  });

  UploadProgress copyWith({
    String? fileId,
    double? progress,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return UploadProgress(
      fileId: fileId ?? this.fileId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
  cancelled,
}

class FileUploadService {
  final ApiClient _apiClient;
  final ImagePicker _imagePicker = ImagePicker();

  FileUploadService(this._apiClient);

  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        Logger.info('Image picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to pick image', error: e);
      throw StorageException(message: 'Failed to pick image: $e');
    }
  }

  Future<List<File>> pickMultipleImages({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      final files = pickedFiles.map((pickedFile) {
        Logger.info('Image picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }).toList();

      return files;
    } catch (e) {
      Logger.error('Failed to pick multiple images', error: e);
      throw StorageException(message: 'Failed to pick multiple images: $e');
    }
  }

  Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (pickedFile != null) {
        Logger.info('Video picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to pick video', error: e);
      throw StorageException(message: 'Failed to pick video: $e');
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required UploadType uploadType,
    String? endpoint,
    Map<String, dynamic>? additionalData,
    Function(double)? onProgress,
  }) async {
    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      Logger.info('Starting file upload: $fileId');

      // Determine endpoint based on upload type
      final uploadEndpoint = endpoint ?? _getEndpointForType(uploadType);

      // Get file info
      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      Logger.info('File info: $fileName, size: $fileSize bytes, type: $mimeType');

      // Validate file size (max 10MB)
      if (fileSize > 10 * 1024 * 1024) {
        throw AppException(message: 'File size exceeds 10MB limit');
      }

      // Prepare form data
      final formData = {
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'upload_type': uploadType.name,
        ...?additionalData,
      };

      // Upload file
      final response = await _apiClient.post(
        uploadEndpoint,
        data: FormData.fromMap(formData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('File upload completed successfully: $fileId');
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(
          message: 'Upload failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      Logger.error('File upload failed', error: e);
      
      if (e is AppException) {
        rethrow;
      }
      
      throw AppException(message: 'File upload failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<File> files,
    required UploadType uploadType,
    String? endpoint,
    Map<String, dynamic>? additionalData,
    Function(int, double)? onProgress,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];
      
      for (int i = 0; i < files.length; i++) {
        final result = await uploadFile(
          file: files[i],
          uploadType: uploadType,
          endpoint: endpoint,
          additionalData: additionalData,
          onProgress: (progress) {
            if (onProgress != null) {
              onProgress(i, progress);
            }
          },
        );
        results.add(result);
      }

      Logger.info('Multiple files upload completed: ${results.length} files');
      return results;
    } catch (e) {
      Logger.error('Multiple files upload failed', error: e);
      rethrow;
    }
  }

  String _getEndpointForType(UploadType type) {
    switch (type) {
      case UploadType.wasteRequestPhoto:
        return '/waste-requests/photos/';
      case UploadType.profilePhoto:
        return '/profiles/photo/';
      case UploadType.evidencePhoto:
        return '/reports/evidence/';
      case UploadType.document:
        return '/documents/';
    }
  }

  Future<String> compressImage(File file, {int quality = 85}) async {
    // Note: This would require adding image compression package
    // For now, we'll return the original file path
    // In production, use packages like 'image' or 'flutter_image_compress'
    Logger.info('Image compression not implemented, using original');
    return file.path;
  }

  Future<bool> deleteFile(String fileId, {String? endpoint}) async {
    try {
      final deleteEndpoint = endpoint ?? '/files/$fileId/';
      
      final response = await _apiClient.delete(deleteEndpoint);
      
      if (response.statusCode == 204) {
        Logger.info('File deleted successfully: $fileId');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Failed to delete file: $fileId', error: e);
      return false;
    }
  }

  Future<String?> getFileUrl(String fileId, {String? endpoint}) async {
    try {
      final urlEndpoint = endpoint ?? '/files/$fileId/url/';
      
      final response = await _apiClient.get(urlEndpoint);
      
      if (response.statusCode == 200) {
        final url = response.data['url'] as String?;
        Logger.info('Retrieved file URL: $url');
        return url;
      }
      
      return null;
    } catch (e) {
      Logger.error('Failed to get file URL: $fileId', error: e);
      return null;
    }
  }
}

final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FileUploadService(apiClient);
});