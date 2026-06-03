import 'dart:io';

import 'api_client.dart';
import 's3_upload_helper.dart';

class AiMediaUpload {
  final String id;
  final String fileName;
  final String contentType;
  final String status;
  final String? mediaUrl;
  final String? uploadUrl;

  AiMediaUpload({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.status,
    this.mediaUrl,
    this.uploadUrl,
  });

  factory AiMediaUpload.fromJson(Map<String, dynamic> json) {
    final nested = json['media'] is Map
        ? Map<String, dynamic>.from(json['media'] as Map)
        : const <String, dynamic>{};

    Object? pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key] ?? nested[key];
        if (value != null && value.toString().trim().isNotEmpty) return value;
      }
      return null;
    }

    return AiMediaUpload(
      id: (pick(['id']) ?? '').toString(),
      fileName: (pick(['fileName', 'file_name']) ?? '').toString(),
      contentType: (pick(['contentType', 'content_type']) ?? '').toString(),
      status: (pick(['status']) ?? '').toString(),
      mediaUrl: pick([
        'mediaUrl',
        'media_url',
        'downloadUrl',
        'download_url',
        'fileUrl',
        'file_url',
        'publicUrl',
        'public_url',
        'imageUrl',
        'image_url',
        's3Url',
        's3_url',
        'objectUrl',
        'object_url',
        'url',
      ])?.toString(),
      uploadUrl: pick([
        'uploadUrl',
        'upload_url',
        'presignedUrl',
        'presigned_url',
      ])?.toString(),
    );
  }
}

class AiMediaService {
  AiMediaService._();
  static final AiMediaService instance = AiMediaService._();

  Future<AiMediaUpload> uploadFile({
    required String filePath,
    String? residentId,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final contentType = _contentType(fileName);
    final requested = await ApiClient.instance.post('/ai/media/upload', body: {
      'fileName': fileName,
      'contentType': contentType,
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
    });
    final upload = AiMediaUpload.fromJson(requested as Map<String, dynamic>);
    if (upload.uploadUrl == null || upload.uploadUrl!.isEmpty) {
      throw ApiException(500, 'لم يرجع الباك اند رابط رفع S3');
    }

    final bytes = await File(filePath).readAsBytes();
    await s3Put(
      uploadUrl: upload.uploadUrl!,
      bytes: bytes,
      contentType: contentType,
      label: fileName,
    );

    final confirmed = await ApiClient.instance.patch(
      '/ai/media/${upload.id}/confirm',
      body: {'notes': 'AI companion media upload'},
    );
    return AiMediaUpload.fromJson(confirmed as Map<String, dynamic>);
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    return 'application/octet-stream';
  }
}
