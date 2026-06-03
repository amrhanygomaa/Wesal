import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../widgets/authenticated_network_image.dart';

class FullScreenImageScreen extends StatefulWidget {
  final String heroTag;
  final String? url;
  final String? assetPath;
  final String? fallbackPath;
  final AssetEntity? assetEntity;
  final String? label;

  const FullScreenImageScreen({
    super.key,
    required this.heroTag,
    this.url,
    this.assetPath,
    this.fallbackPath,
    this.assetEntity,
    this.label,
  });

  @override
  State<FullScreenImageScreen> createState() => _FullScreenImageScreenState();
}

class _FullScreenImageScreenState extends State<FullScreenImageScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        actions: [
          IconButton(
            tooltip: 'حفظ الصورة',
            onPressed: _isSaving ? null : _saveImageToDevice,
            icon: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: widget.heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          if (widget.label != null && widget.label!.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final candidates = _imageCandidates();
    if (candidates.isNotEmpty) {
      return _buildPathImage(candidates);
    }
    if (widget.assetEntity != null) {
      return AssetEntityImage(
        widget.assetEntity!,
        isOriginal: true,
        fit: BoxFit.contain,
      );
    }
    return const Icon(Icons.broken_image, color: Colors.white, size: 50);
  }

  Widget _buildPathImage(List<String> paths, {int index = 0}) {
    if (index >= paths.length) {
      return const Icon(Icons.broken_image, color: Colors.white, size: 50);
    }

    final path = paths[index];
    final fallback = _buildPathImage(paths, index: index + 1);
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final resolvedUrl = _resolveUrl(path);
    if (resolvedUrl.startsWith('http')) {
      return AuthenticatedNetworkImage(
        key: ValueKey(resolvedUrl),
        url: resolvedUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }

  List<String> _imageCandidates() {
    final seen = <String>{};
    return [widget.url, widget.assetPath, widget.fallbackPath]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .where((value) => seen.add(value))
        .toList();
  }

  Future<void> _saveImageToDevice() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth && !permission.hasAccess) {
        PhotoManager.openSetting();
        throw Exception('يحتاج التطبيق إذن الوصول للصور');
      }

      final saved = await _saveFirstAvailableImage();
      if (!saved) {
        throw Exception('تعذر العثور على صورة صالحة للحفظ');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الصورة على جهازك'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ الصورة: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _saveFirstAvailableImage() async {
    for (final path in _imageCandidates()) {
      if (path.startsWith('assets/')) continue;

      final resolvedUrl = _resolveUrl(path);
      if (resolvedUrl.startsWith('http')) {
        final response = await _downloadNetworkImage(resolvedUrl);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await PhotoManager.editor.saveImage(
            response.bodyBytes,
            filename: _fileNameFromPath(resolvedUrl),
            title: 'Wanas photo',
          );
          return true;
        }
        continue;
      }

      final file = File(path);
      if (await file.exists()) {
        await PhotoManager.editor.saveImageWithPath(
          file.path,
          title: 'Wanas photo',
        );
        return true;
      }
    }

    final entityFile = await widget.assetEntity?.file;
    if (entityFile != null && await entityFile.exists()) {
      await PhotoManager.editor.saveImageWithPath(
        entityFile.path,
        title: 'Wanas photo',
      );
      return true;
    }

    return false;
  }

  Future<http.Response> _downloadNetworkImage(String url) async {
    final headers = <String, String>{};
    final apiUri = Uri.tryParse(ApiConfig.baseUrl);
    final uri = Uri.tryParse(url);
    if (apiUri != null &&
        uri != null &&
        uri.scheme == apiUri.scheme &&
        uri.host == apiUri.host) {
      final token = await ApiClient.instance.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return http.get(Uri.parse(url), headers: headers);
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith('/') && !raw.startsWith('//')) {
      return '${ApiConfig.baseUrl}$raw';
    }
    return raw;
  }

  String _fileNameFromPath(String raw) {
    final path = Uri.tryParse(raw)?.path ?? raw;
    final name = path.split('/').where((part) => part.isNotEmpty).lastOrNull;
    if (name == null || !name.contains('.')) {
      return 'wanas_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return name;
  }
}
