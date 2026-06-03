import 'dart:io';

import 'api_client.dart';
import 's3_upload_helper.dart';

class BackendVoiceMessageUpload {
  final Map<String, dynamic> message;
  final String? uploadUrl;

  BackendVoiceMessageUpload({required this.message, this.uploadUrl});

  factory BackendVoiceMessageUpload.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message'] is Map ? json['message'] : json;
    return BackendVoiceMessageUpload(
      message: Map<String, dynamic>.from(rawMessage as Map),
      uploadUrl: (json['uploadUrl'] ??
              json['upload_url'] ??
              json['presignedUrl'] ??
              json['presigned_url'])
          ?.toString(),
    );
  }
}

class VoiceMessageService {
  VoiceMessageService._();
  static final VoiceMessageService instance = VoiceMessageService._();

  Future<BackendVoiceMessageUpload> create({
    required String residentId,
    required String title,
    String senderType = 'resident',
    String? recipientId,
    String? familyMemberId,
    String? filePath,
    int durationSeconds = 0,
  }) async {
    final fileName = filePath == null ? null : _fileName(filePath);
    final contentType = fileName == null ? null : _contentType(fileName);
    final res = await ApiClient.instance.post('/voice-messages/upload', body: {
      'residentId': residentId,
      'senderType': senderType,
      'title': title,
      'durationSeconds': durationSeconds,
      if (recipientId != null && recipientId.isNotEmpty)
        'recipientId': recipientId,
      if (familyMemberId != null && familyMemberId.isNotEmpty)
        'familyMemberId': familyMemberId,
      if (fileName != null) 'fileName': fileName,
      if (contentType != null) 'contentType': contentType,
    });
    final upload = BackendVoiceMessageUpload.fromJson(
      res as Map<String, dynamic>,
    );

    if (filePath != null && upload.uploadUrl != null) {
      final bytes = await File(filePath).readAsBytes();
      await s3Put(
        uploadUrl: upload.uploadUrl!,
        bytes: bytes,
        contentType: contentType ?? 'audio/mpeg',
        label: _fileName(filePath),
      );
      return _confirmUpload(
        upload.message,
        fileSizeBytes: bytes.length,
        durationSeconds: durationSeconds,
      );
    }

    return upload;
  }

  Future<BackendVoiceMessageUpload> _confirmUpload(
    Map<String, dynamic> message, {
    required int fileSizeBytes,
    required int durationSeconds,
  }) async {
    final id = (message['id'] ?? '').toString();
    if (id.isEmpty) return BackendVoiceMessageUpload(message: message);

    try {
      final confirmed = await ApiClient.instance.patch(
        '/voice-messages/$id/confirm',
        body: {
          'fileSizeBytes': fileSizeBytes,
          'durationSeconds': durationSeconds,
        },
      );
      return BackendVoiceMessageUpload.fromJson(
        Map<String, dynamic>.from(confirmed as Map),
      );
    } on ApiException catch (e) {
      final missingConfirmEndpoint = e.statusCode == 404 || e.statusCode == 405;
      if (!missingConfirmEndpoint) rethrow;
      return BackendVoiceMessageUpload(message: message);
    }
  }

  String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mpeg';
  }
}
