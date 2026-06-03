import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 's3_upload_helper.dart';

class BackendFamilyMedia {
  final String id;
  final String residentId;
  final String fileName;
  final String contentType;
  final String status;
  final String? caption;
  final int? fileSizeBytes;
  final String? mediaUrl;
  final String createdAt;

  BackendFamilyMedia({
    required this.id,
    required this.residentId,
    required this.fileName,
    required this.contentType,
    required this.status,
    this.caption,
    this.fileSizeBytes,
    this.mediaUrl,
    required this.createdAt,
  });

  factory BackendFamilyMedia.fromJson(Map<String, dynamic> j) {
    final data =
        j['media'] is Map ? Map<String, dynamic>.from(j['media'] as Map) : j;
    String? pickString(List<String> keys) {
      for (final key in keys) {
        final value = data[key] ?? j[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    return BackendFamilyMedia(
      id: pickString(['id']) ?? '',
      residentId: pickString(['residentId', 'resident_id']) ?? '',
      fileName: pickString(['fileName', 'file_name']) ?? '',
      contentType: pickString(['contentType', 'content_type']) ?? '',
      status: pickString(['status']) ?? '',
      caption: pickString(['caption']),
      fileSizeBytes: (data['fileSizeBytes'] ?? data['file_size_bytes']) is num
          ? ((data['fileSizeBytes'] ?? data['file_size_bytes']) as num).toInt()
          : null,
      mediaUrl: pickString([
        'mediaUrl',
        'media_url',
        'downloadUrl',
        'download_url',
        'imageUrl',
        'image_url',
        'publicUrl',
        'public_url',
        'fileUrl',
        'file_url',
        's3Url',
        's3_url',
        'objectUrl',
        'object_url',
        'url',
      ]),
      createdAt: pickString(['createdAt', 'created_at']) ?? '',
    );
  }
}

class FamilyMediaService {
  FamilyMediaService._();
  static final FamilyMediaService instance = FamilyMediaService._();

  Future<List<BackendFamilyMedia>> list({
    String? residentId,
    String status = 'confirmed',
  }) async {
    final res = await ApiClient.instance.get('/family-bridge/media', query: {
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
      if (status.isNotEmpty) 'status': status,
    });
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => BackendFamilyMedia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BackendFamilyMedia> uploadImage({
    required String residentId,
    required XFile image,
    String? caption,
  }) async {
    final contentType = image.mimeType ?? _contentTypeForName(image.name);
    final requested = await ApiClient.instance.post(
      '/family-bridge/media/upload',
      body: {
        'residentId': residentId,
        'fileName': image.name.isEmpty ? 'family-photo.jpg' : image.name,
        'contentType': contentType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
    );

    final uploadMap = Map<String, dynamic>.from(requested as Map);
    final uploadUrl =
        (uploadMap['presignedUrl'] ?? uploadMap['uploadUrl'] ?? '').toString();
    final media = BackendFamilyMedia.fromJson(
      uploadMap['media'] is Map
          ? Map<String, dynamic>.from(uploadMap['media'] as Map)
          : uploadMap,
    );
    if (uploadUrl.isEmpty || media.id.isEmpty) {
      throw ApiException(500, 'Invalid family media upload response');
    }

    final bytes = await image.readAsBytes();
    await s3Put(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      label: image.name,
    );

    final confirmedRaw = await ApiClient.instance.patch(
      '/family-bridge/media/${media.id}/confirm',
      body: {'fileSizeBytes': bytes.length},
    );
    final confirmed = BackendFamilyMedia.fromJson(
        Map<String, dynamic>.from(confirmedRaw as Map));
    if ((confirmed.mediaUrl ?? '').trim().isNotEmpty) return confirmed;
    return BackendFamilyMedia(
      id: confirmed.id.isNotEmpty ? confirmed.id : media.id,
      residentId: confirmed.residentId.isNotEmpty
          ? confirmed.residentId
          : media.residentId,
      fileName:
          confirmed.fileName.isNotEmpty ? confirmed.fileName : media.fileName,
      contentType: confirmed.contentType.isNotEmpty
          ? confirmed.contentType
          : media.contentType,
      status: confirmed.status.isNotEmpty ? confirmed.status : media.status,
      caption: confirmed.caption ?? media.caption,
      fileSizeBytes: confirmed.fileSizeBytes ?? bytes.length,
      mediaUrl: media.mediaUrl,
      createdAt: confirmed.createdAt.isNotEmpty
          ? confirmed.createdAt
          : media.createdAt,
    );
  }

  Future<void> delete(String id) {
    return ApiClient.instance.delete('/family-bridge/media/$id');
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
