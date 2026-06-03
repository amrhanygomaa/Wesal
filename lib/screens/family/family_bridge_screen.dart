import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/family_media_service.dart';
import '../../widgets/authenticated_network_image.dart';
import '../../widgets/taptaba_scaffold.dart';
import '../elderly/full_screen_image_screen.dart';

// شاشة "جسر العائلة" - تتيح للأقارب التواصل مع المقيم عبر الصور والرسائل الصوتية
class FamilyBridgeScreen extends ConsumerStatefulWidget {
  const FamilyBridgeScreen({super.key});

  @override
  ConsumerState<FamilyBridgeScreen> createState() => _FamilyBridgeScreenState();
}

class _FamilyBridgeScreenState extends ConsumerState<FamilyBridgeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotationController;
  bool _isUploading = false; // حالة الرفع الحالية
  double _uploadProgress = 0.0; // نسبة تقدم الرفع
  String _uploadStatus = ''; // نص حالة الرفع
  bool _showDoneAnimation = false; // هل نعرض أنيميشن الانتهاء؟
  bool _showDeleteAnimation = false; // هل نعرض أنيميشن الحذف؟

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // فتح المعرض واختيار صورة
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showConfirmUpload('صورة', imagePath: image.path);
    }
  }

  Future<void> _uploadToAws(String title, String type,
      {String? imagePath}) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'جاري رفع $type...';
      _showDoneAnimation = false;
    });

    final provider = ref.read(appRiverpod);
    provider.backendSyncError = null;
    final residentId = provider.currentAccount?.linkedResidentId ??
        (provider.residentFiles.isNotEmpty
            ? provider.residentFiles.first.id
            : null);
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'المقيم';

    var completed = false;
    if (residentId == null || residentId.isEmpty) {
      provider.backendSyncError = 'لا يوجد مقيم مربوط من السيرفر';
    } else if (type == 'صورة' && imagePath != null) {
      final localPath = await provider.persistAlbumImage(imagePath);
      final localMomentId =
          'local_family_${DateTime.now().millisecondsSinceEpoch}';
      provider.upsertMemoryMoment(
        MemoryMoment(
          id: localMomentId,
          residentId: residentId,
          residentName: residentName,
          imageUrl: localPath,
          activityTitle: title,
          date: 'الآن',
          appreciations: 0,
        ),
      );
      setState(() => _uploadProgress = 0.35);
      try {
        final uploaded = await FamilyMediaService.instance.uploadImage(
          residentId: residentId,
          image: XFile(imagePath),
          caption: title,
        );
        setState(() => _uploadProgress = 0.7);
        final remoteUrl = (uploaded.mediaUrl ?? '').trim();
        if (remoteUrl.isEmpty) {
          throw ApiException(500, 'لم يرجع السيرفر رابط الصورة بعد الرفع');
        }
        provider.upsertMemoryMoment(
          MemoryMoment(
            id: uploaded.id.isEmpty
                ? 'fb_${DateTime.now().millisecondsSinceEpoch}'
                : 'fb_${uploaded.id}',
            residentId: residentId,
            residentName: residentName,
            imageUrl: remoteUrl,
            fallbackPath: localPath,
            activityTitle: uploaded.caption?.trim().isNotEmpty == true
                ? uploaded.caption!.trim()
                : title,
            date: 'الآن',
            appreciations: 0,
          ),
          replaceId: localMomentId,
        );
        provider.backendSyncError = null;
        completed = true;
        unawaited(provider.syncBackendData());
      } catch (e) {
        provider.backendSyncError = 'تعذر رفع الصورة. حاول مرة أخرى بعد قليل.';
        completed = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'تم حفظ الصورة محليا، وتعذر رفعها للسيرفر. حاول مرة أخرى بعد قليل.'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
      }
    } else {
      setState(() => _uploadProgress = 0.4);
      await provider.sendVoiceMessageFromFamily(
        title,
        durationSeconds: 0,
      );
      completed = true;
    }

    setState(() {
      _uploadProgress = completed ? 1.0 : 0.0;
      _showDoneAnimation = completed;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isUploading = false;
        _showDoneAnimation = false;
      });
    }
  }

  // إظهار نافذة تأكيد قبل الرفع الفعلي
  void _showConfirmUpload(String type, {String? imagePath}) {
    String title = type == 'صورة' ? '' : 'رسالة صوتية للأب';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('تأكيد الإرسال',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 8),
            Text('هل تريد إرسال ال$type الآن إلى المقيم المرتبط بحسابك؟',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748b))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _uploadToAws(title, type, imagePath: imagePath);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFea580c),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('تأكيد وإرسال',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFe2e8f0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Color(0xFF64748b))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final residentId = provider.currentAccount?.linkedResidentId ??
        (provider.residentFiles.isNotEmpty
            ? provider.residentFiles.first.id
            : null);
    final moments = provider.memoryWallMoments(residentId: residentId);

    return TaptabaScaffold(
      title: 'جسر العائلة',
      overrideRole: 'عائلة',
      hideAppBar: true,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildUploadActions(), // أزرار الرفع (صوت وصورة)
              Expanded(child: _buildGallery(moments)), // معرض الذكريات المرفوعة
            ],
          ),
          if (_isUploading) _buildUploadOverlay(), // واجهة التحميل عند الرفع
          if (_showDeleteAnimation) _buildDeleteOverlay(), // أنيميشن الحذف
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFea580c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('جسر العائلة',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Orb 1 - Top Right
            Positioned(
              top: -50 + (30 * _floatController.value),
              right: -40 + (20 * _floatController.value),
              child: _buildRealisticOrb(180, [
                const Color(0xFFfb923c).withValues(alpha: 0.35),
                const Color(0xFFea580c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            // Orb 2 - Bottom Left
            Positioned(
              bottom: -30 + (40 * (1 - _floatController.value)),
              left: -40 + (25 * _floatController.value),
              child: _buildRealisticOrb(160, [
                const Color(0xFFfdba74).withValues(alpha: 0.3),
                const Color(0xFFf97316).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
            // Orb 3 - Center
            Positioned(
              top: 40,
              left: 100,
              child: _buildRealisticOrb(70, [
                const Color(0xFFfb923c).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealisticOrb(double size, List<Color> baseColors) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: baseColors,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            RotationTransition(
              turns: _rotationController,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * 0.1,
              left: size * 0.15,
              child: Container(
                width: size * 0.4,
                height: size * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: const Color(0xFFea580c),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b))),
      ],
    );
  }

  // بناء أزرار التفاعل السريع للرفع
  Widget _buildUploadActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSectionHeader('شارك لحظة جديدة'),
          const SizedBox(height: 16),
          Row(
            children: [
              _uploadBtn(Icons.image_rounded, 'صورة جديدة',
                  const Color(0xFF0ea5e9), _pickAndUploadImage),
            ],
          ),
        ],
      ),
    );
  }

  // بناء زر الرفع الفردي بتصميم عصري
  Widget _uploadBtn(
      IconData icon, String label, Color color, VoidCallback onTap,
      {bool isRecording = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isRecording
                ? Colors.red.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isRecording ? Colors.red : color.withValues(alpha: 0.3),
                width: 1.5),
          ),
          child: Column(
            children: [
              Icon(isRecording ? Icons.stop_circle_rounded : icon,
                  color: isRecording ? Colors.red : color, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: isRecording ? Colors.red : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة', textAlign: TextAlign.center),
        content: const Text(
            'هل أنت متأكد أنك تريد حذف هذه الصورة من حائط الذكريات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() {
                _showDeleteAnimation = true;
              });

              ref.read(appRiverpod).deleteMemoryMoment(id);

              await Future.delayed(const Duration(milliseconds: 1500));

              if (mounted) {
                setState(() {
                  _showDeleteAnimation = false;
                });
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // بناء معرض الصور والرسائل المرفوعة (Grid View)
  Widget _buildGallery(List<MemoryMoment> moments) {
    final displayMoments =
        moments.where((m) => _isDisplayableImagePath(m.imageUrl)).toList();

    if (displayMoments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFFEA580C), size: 34),
              ),
              const SizedBox(height: 14),
              const Text(
                'لا توجد صور عائلية بعد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'شارك أول صورة لتظهر في حائط الذكريات.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: displayMoments.length,
      itemBuilder: (context, i) {
        final m = displayMoments[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: const Color(0xFFf1f5f9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _openImageViewer(m),
                        child: Hero(
                          tag: 'family_bridge_${m.id}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: _buildMemoryMomentImage(
                              m.imageUrl,
                              fallbackPath: m.fallbackPath,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => _saveMomentImage(m),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.download_rounded,
                              color: Color(0xFF0EA5E9), size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          _showDeleteConfirmation(context, ref, m.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_shouldShowMomentTitle(m.activityTitle)) ...[
                      Text(m.activityTitle,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b))),
                      const SizedBox(height: 2),
                    ],
                    Text(m.date,
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF94a3b8))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemoryMomentImage(String imageUrl, {String? fallbackPath}) {
    final paths = _imageCandidates(imageUrl, fallbackPath);
    if (paths.isEmpty) return _buildImageFallback();
    return _buildImageFromCandidates(paths);
  }

  Widget _buildImageFromCandidates(List<String> paths, {int index = 0}) {
    if (index >= paths.length) return _buildImageFallback();
    final path = paths[index];
    final fallback = _buildImageFromCandidates(paths, index: index + 1);
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    }

    final resolvedUrl = _resolveImageUrl(path);
    if (resolvedUrl.startsWith('http') ||
        resolvedUrl.startsWith('blob') ||
        resolvedUrl.startsWith('data:image')) {
      return AuthenticatedNetworkImage(
        url: resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }

  bool _isDisplayableImagePath(String imageUrl) {
    final path = imageUrl.trim();
    if (path.isEmpty) return false;
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:image') ||
        (path.startsWith('/') && !path.startsWith('//'))) {
      return true;
    }
    if (path.startsWith('assets/')) return true;
    if (!kIsWeb) return File(path).existsSync();
    return false;
  }

  List<String> _imageCandidates(String imageUrl, String? fallbackPath) {
    final seen = <String>{};
    return [imageUrl, fallbackPath]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .where((value) => seen.add(value))
        .toList();
  }

  bool _shouldShowMomentTitle(String title) {
    final clean = title.trim();
    return clean.isNotEmpty &&
        clean != 'صورة عائلية جديدة' &&
        clean != 'لحظة عائلية' &&
        clean != 'صورة جديدة';
  }

  void _openImageViewer(MemoryMoment moment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageScreen(
          heroTag: 'family_bridge_${moment.id}',
          url: moment.imageUrl,
          fallbackPath: moment.fallbackPath,
        ),
      ),
    );
  }

  Future<void> _saveMomentImage(MemoryMoment moment) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth && !permission.hasAccess) {
        PhotoManager.openSetting();
        throw Exception('يحتاج التطبيق إذن الوصول للصور');
      }

      final saved = await _saveFirstAvailableImage(
        _imageCandidates(moment.imageUrl, moment.fallbackPath),
      );
      if (!saved) throw Exception('تعذر العثور على صورة صالحة للحفظ');

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
    }
  }

  Future<bool> _saveFirstAvailableImage(List<String> paths) async {
    for (final imageUrl in paths) {
      final saved = await _saveImagePath(imageUrl);
      if (saved) return true;
    }
    return false;
  }

  Future<bool> _saveImagePath(String imageUrl) async {
    final path = imageUrl.trim();
    if (path.isEmpty || path.startsWith('assets/')) return false;

    final resolvedUrl = _resolveImageUrl(path);
    if (resolvedUrl.startsWith('http')) {
      final response = await _downloadNetworkImage(resolvedUrl);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await PhotoManager.editor.saveImage(
          response.bodyBytes,
          filename: _fileNameFromPath(resolvedUrl),
          title: 'Wanas family photo',
        );
        return true;
      }
      return false;
    }

    if (!kIsWeb) {
      final file = File(path);
      if (await file.exists()) {
        await PhotoManager.editor.saveImageWithPath(
          file.path,
          title: 'Wanas family photo',
        );
        return true;
      }
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

  String _resolveImageUrl(String raw) {
    if (raw.startsWith('/') && !raw.startsWith('//')) {
      return '${ApiConfig.baseUrl}$raw';
    }
    return raw;
  }

  String _fileNameFromPath(String raw) {
    final path = Uri.tryParse(raw)?.path ?? raw;
    final name = path.split('/').where((part) => part.isNotEmpty).lastOrNull;
    if (name == null || !name.contains('.')) {
      return 'wanas_family_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return name;
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFFFF7ED),
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: Color(0xFFEA580C), size: 30),
      ),
    );
  }

  // واجهة التغطية (Overlay) التي تظهر أثناء عملية الرفع
  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _showDoneAnimation
                ? [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تم بنجاح!',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ]
                : [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFf1f5f9),
                        color: const Color(0xFFea580c),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(_uploadStatus,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress * 100).toInt()}% اكتمل',
                        style: const TextStyle(color: Color(0xFF64748b))),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 70,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'تم الحذف!',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
