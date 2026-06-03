import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../services/ai_media_service.dart';
import '../../widgets/authenticated_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'full_screen_image_screen.dart';

class AlbumDetailsScreen extends ConsumerWidget {
  final String albumName;

  const AlbumDetailsScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    bool hc = provider.isHighContrast;

    // الحصول على الصور الخاصة بهذا الألبوم
    List<dynamic> items = provider.getMemoriesByCategory(albumName);

    return Scaffold(
      backgroundColor: hc ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          albumName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: hc ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        iconTheme:
            IconThemeData(color: hc ? Colors.white : const Color(0xFF0F172A)),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded,
                      size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('الألبوم فارغ',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('اضغط على الزر أدناه لإضافة صور',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withValues(alpha: 0.6))),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final mem = items[index];
                String type = 'image';
                String? url;
                String? assetPath;
                String? fallbackPath;

                if (mem is MemoryItem) {
                  type = mem.type;
                  assetPath = mem.assetPath;
                  fallbackPath = mem.content;
                } else if (mem is MemoryMoment) {
                  type = 'image';
                  url = mem.imageUrl;
                  fallbackPath = mem.fallbackPath;
                } else if (mem is String) {
                  type = 'image';
                  url = mem;
                }

                return _buildPhotoCell(context, index, type, url, assetPath,
                    fallbackPath, hc, mem, ref);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? image =
              await picker.pickImage(source: ImageSource.gallery);
          if (image == null) return;

          final provider = ref.read(appRiverpod);
          final residentId = provider.backendResidentId ??
              (provider.residentFiles.isNotEmpty
                  ? provider.residentFiles.first.id
                  : null);
          final localPath = await provider.persistAlbumImage(image.path);
          final itemId = provider.addPhotoToAlbum(albumName, localPath);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حفظ الصورة في الألبوم'),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          }
          try {
            final uploaded = await AiMediaService.instance.uploadFile(
              filePath: image.path,
              residentId: residentId,
            );
            final s3Url = uploaded.mediaUrl;
            if (s3Url != null && s3Url.isNotEmpty) {
              provider.updateMemoryItemAssetPath(itemId, s3Url);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('تم حفظ الصورة محلياً، لكن تعذر رفعها للسيرفر: $e'),
                  backgroundColor: Colors.orange.shade700,
                ),
              );
            }
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text('إضافة صورة',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildPhotoCell(
      BuildContext context,
      int index,
      String type,
      String? url,
      String? assetPath,
      String? fallbackPath,
      bool hc,
      dynamic mem,
      WidgetRef ref) {
    final imagePaths = _imageCandidates(url, assetPath, fallbackPath);
    final hasImage = imagePaths.isNotEmpty;
    final heroTag = 'album_photo_${albumName}_$index';

    Widget cellContent = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            _buildImageFromCandidates(imagePaths, highContrast: hc)
          else
            _buildImageFallback(hc),
          if (type == 'video')
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          if (hasImage && type != 'video')
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(Icons.open_in_full_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: hc ? const Color(0xFF1E1E1E) : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.image_rounded, color: Color(0xFF6C63FF)),
                  title: Text('تعيين كواجهة للألبوم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hc ? Colors.white : Colors.black)),
                  onTap: () {
                    String coverImg = url ?? assetPath ?? fallbackPath ?? '';
                    if (coverImg.isNotEmpty) {
                      ref.read(appRiverpod).setAlbumCover(albumName, coverImg);
                    }
                    Navigator.pop(context);
                  },
                ),
                if (mem is MemoryItem)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_rounded, color: Colors.red),
                    title: const Text('مسح الصورة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                    onTap: () {
                      ref.read(appRiverpod).deleteMemoryItem(mem.id);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      onTap: () {
        if (hasImage && type != 'video') {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FullScreenImageScreen(
                heroTag: heroTag,
                url: url,
                assetPath: assetPath,
                fallbackPath: fallbackPath,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      },
      child: Hero(
        tag: heroTag,
        child: Material(color: Colors.transparent, child: cellContent),
      ),
    );
  }

  List<String> _imageCandidates(
    String? url,
    String? assetPath,
    String? fallbackPath,
  ) {
    final seen = <String>{};
    return [url, assetPath, fallbackPath]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .where((value) => seen.add(value))
        .toList();
  }

  Widget _buildImageFromCandidates(
    List<String> paths, {
    int index = 0,
    required bool highContrast,
  }) {
    if (index >= paths.length) return _buildImageFallback(highContrast);
    final path = paths[index];
    final fallback = _buildImageFromCandidates(
      paths,
      index: index + 1,
      highContrast: highContrast,
    );

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final resolvedUrl = _resolveImageUrl(path);
    if (resolvedUrl.startsWith('http')) {
      return AuthenticatedNetworkImage(
        url: resolvedUrl,
        fit: BoxFit.cover,
        loadingBuilder: (_) => _buildImageLoading(),
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }

  String _resolveImageUrl(String raw) {
    if (raw.startsWith('/') && !raw.startsWith('//')) {
      return '${ApiConfig.baseUrl}$raw';
    }
    return raw;
  }

  Widget _buildImageLoading() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _buildImageFallback(bool highContrast) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highContrast
              ? const [Color(0xFF1E1E1E), Color(0xFF2A2A2A)]
              : const [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Color(0xFF94A3B8), size: 34),
      ),
    );
  }
}
