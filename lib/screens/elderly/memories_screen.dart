import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_riverpod.dart';
import 'voice_messages_playback_screen.dart';
import 'album_details_screen.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _floatController;
  late AnimationController _heartController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late AnimationController _noteController;
  late AnimationController _shimmerController;

  // الألبومات أصبحت ديناميكية

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat(reverse: true);
    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat();
    _noteController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    // تحميل صور الجهاز والألبومات المحفوظة عند الدخول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appRiverpod).fetchGalleryImages();
      ref.read(appRiverpod).loadLocalAlbums();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    _heartController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    _noteController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHero(provider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildAlbumsGrid(provider),
                  const SizedBox(height: 12),
                  _buildFamilyNote(provider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(AppRiverpod provider) {
    int photoCount = provider
        .getMemoriesByCategory(AppRiverpod.defaultPhotoAlbumName)
        .length;
    int videoCount =
        provider.memoriesList.where((m) => m.type == 'video').length;
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a0533),
                Color(0xFF3730a3),
                Color(0xFF0f3460),
                Color(0xFF6C63FF)
              ],
            ),
          ),
          child: Stack(
            children: [
              _buildBlob(180, const Color(0xFF6C63FF), -50, -50, 7),
              _buildBlob(130, const Color(0xFFf472b6), -35, 30, 9),
              _buildBlob(80, const Color(0xFFc084fc), 80, -10, 6),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 28, top: 4, bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('ذكرياتي الحلوة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 4),
                          Text('من الأسرة بكل الحب 💜',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 12, bottom: 24),
                      child: Row(
                        children: [
                          _buildHeroChip('$photoCount', 'صورة', 0),
                          const SizedBox(width: 8),
                          _buildHeroChip(' $videoCount', 'فيديو', 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlob(
      double size, Color color, double right, double top, double duration) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value * 2 * pi;
        final x = sin(t * (duration / 7)) * 10;
        final y = cos(t * (duration / 7)) * 12;
        return Positioned(
          left: right + x,
          top: top + y,
          child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withValues(alpha: 0.4))),
        );
      },
    );
  }

  Widget _buildHeroChip(String value, String label, int index) {
    Color chipColor;
    Color borderColor;

    switch (index) {
      case 0: // صورة
        chipColor =
            const Color(0xFFF472B6).withValues(alpha: 0.15); // وردي خفيف
        borderColor = const Color(0xFFF472B6).withValues(alpha: 0.3);
        break;
      case 1: // فيديو
        chipColor =
            const Color(0xFF8B5CF6).withValues(alpha: 0.15); // بنفسجي فاتح
        borderColor = const Color(0xFF8B5CF6).withValues(alpha: 0.3);
        break;
      case 2: // رسالة
        chipColor = const Color(0xFF3B82F6).withValues(alpha: 0.15); // أزرق
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        break;
      default:
        chipColor = Colors.white.withValues(alpha: 0.14);
        borderColor = Colors.white.withValues(alpha: 0.12);
    }

    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.6, end: 1),
        duration: Duration(milliseconds: 450 + (index * 120)),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  // تم إزالة أزرار التصنيفات (Categories Tabs)

  // ignore: unused_element
  Widget _buildFeaturedCard() {
    final provider = ref.watch(appRiverpod);
    bool hc = provider.isHighContrast;
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _glowController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * _floatController.value),
          child: Container(
            decoration: BoxDecoration(
              color: hc ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: hc ? const Color(0xFF333333) : const Color(0xFFddd6fe),
                  width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF6C63FF)
                        .withValues(alpha: hc ? 0.25 : 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 6)),
                BoxShadow(
                    color: const Color(0xFFa78bfa).withValues(
                        alpha:
                            hc ? 0.2 : (0.35 + (_glowController.value * 0.45))),
                    blurRadius: 12 + (_glowController.value * 12),
                    spreadRadius: _glowController.value * 6),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  Container(
                    height: 140,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFFddd6fe),
                        Color(0xFFc4b5fd),
                        Color(0xFFf9a8d4)
                      ]),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF)
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('🌟 ذكرى اليوم',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 16,
                                      offset: Offset(0, 4))
                                ]),
                            child: const Icon(Icons.play_arrow,
                                color: Color(0xFF6C63FF), size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  provider.memoriesList.isNotEmpty
                                      ? provider.memoriesList.first.title
                                      : 'لا توجد ذكريات من السيرفر',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: hc
                                          ? Colors.white
                                          : const Color(0xFF0f172a))),
                              const SizedBox(height: 6),
                              Text('من ألبوم السيرفر',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: hc
                                          ? Colors.white70
                                          : Colors.grey[500],
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedBuilder(
                          animation: _heartController,
                          builder: (context, child) {
                            final t = _heartController.value * 2 * pi;
                            final scale =
                                1 + (sin(t) * 0.12) + (sin(t * 2) * 0.08);
                            return Transform.scale(scale: scale, child: child);
                          },
                          child:
                              const Text('💜', style: TextStyle(fontSize: 22)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildVoiceMessage(AppRiverpod provider) {
    final unreadCount = provider.voiceMessages.where((v) => v.isUnread).length;
    final latestMsg =
        provider.voiceMessages.isNotEmpty ? provider.voiceMessages.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const VoiceMessagesPlaybackScreen())),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFF6C63FF),
            Color(0xFFA78BFA),
            Color(0xFFc084fc)
          ]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                  right: -15,
                  top: -15,
                  child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1)))),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  latestMsg != null
                                      ? latestMsg.title
                                      : 'رسائل الأسرة',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  unreadCount > 0
                                      ? 'لديك $unreadCount رسائل جديدة ✨'
                                      : 'استمع لرسائل أحبائك',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 10),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFf43f5e),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('$unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildWaveBar(double height, int index) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final delay = index * 0.1;
        final t = (_waveController.value + delay) % 1;
        final scale = 1 + (sin(t * pi * 2) * 0.8);
        return Transform.scale(
          scaleY: scale,
          child: Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(2))),
        );
      },
    );
  }

  Widget _buildAlbumsGrid(AppRiverpod provider) {
    bool hc = provider.isHighContrast;
    final albums = provider.allAlbums;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: hc ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: hc
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF6C63FF).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: hc ? const Color(0xFF333333) : Colors.white,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.photo_album_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ألبومات الصور',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              color:
                                  hc ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('مجلدات ذكرياتك ✨',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hc
                                  ? Colors.white70
                                  : const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showCreateAlbumDialog(context, provider),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.create_new_folder_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('ألبوم',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (albums.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF8B5CF6), size: 34),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد صور مرفوعة حتى الآن',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748b)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ابدأ بإنشاء ألبوم وإضافة صور ذكرياتك',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final albumName = albums[index];
              final itemsCount =
                  provider.getMemoriesByCategory(albumName).length;
              return _buildAlbumCell(
                  context, provider, index, albumName, itemsCount, hc);
            },
          ),
      ],
    );
  }

  Widget _buildAlbumCell(BuildContext context, AppRiverpod provider, int index,
      String albumName, int itemsCount, bool hc) {
    final gradients = [
      const [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
      const [Color(0xFFEC4899), Color(0xFFF9A8D4)],
      const [Color(0xFF3B82F6), Color(0xFF93C5FD)],
      const [Color(0xFF10B981), Color(0xFF6EE7B7)],
      const [Color(0xFFF59E0B), Color(0xFFFCD34D)],
      const [Color(0xFFF43F5E), Color(0xFFFDA4AF)],
    ];
    final gradient = gradients[index % gradients.length];

    final coverPath = provider.albumCovers[albumName];
    final hasCover = coverPath != null && coverPath.isNotEmpty;

    return GestureDetector(
      onLongPress: () =>
          _showAlbumOptionsSheet(context, provider, albumName, hc),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AlbumDetailsScreen(albumName: albumName)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: hasCover
              ? null
              : LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
          image: hasCover
              ? (coverPath.startsWith('http')
                  ? DecorationImage(
                      image: NetworkImage(coverPath), fit: BoxFit.cover)
                  : (coverPath.startsWith('assets/')
                      ? DecorationImage(
                          image: AssetImage(coverPath), fit: BoxFit.cover)
                      : DecorationImage(
                          image: FileImage(File(coverPath)),
                          fit: BoxFit.cover)))
              : null,
          boxShadow: [
            BoxShadow(
              color: (hasCover ? Colors.black : gradient[0])
                  .withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (hasCover)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              if (!hasCover)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(Icons.folder_rounded,
                      size: 120, color: Colors.white.withValues(alpha: 0.2)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      albumName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemsCount صورة/فيديو',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlbumOptionsSheet(
      BuildContext context, AppRiverpod provider, String albumName, bool hc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hc ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                albumName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hc ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const Divider(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.drive_file_rename_outline_rounded,
                    color: Color(0xFF6C63FF)),
              ),
              title: Text('تعديل اسم الألبوم',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hc ? Colors.white : Colors.black)),
              subtitle: Text('تغيير اسم الألبوم الحالي',
                  style: TextStyle(
                      color: hc ? Colors.white54 : Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameAlbumDialog(context, provider, albumName, hc);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
              title: const Text('حذف الألبوم',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: const Text('سيتم حذف الألبوم وكل الصور بداخله',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteAlbumConfirm(context, provider, albumName, hc);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRenameAlbumDialog(
      BuildContext context, AppRiverpod provider, String albumName, bool hc) {
    final controller = TextEditingController(text: albumName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hc ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل اسم الألبوم',
            style: TextStyle(
                color: hc ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: hc ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'الاسم الجديد',
            hintStyle: TextStyle(color: hc ? Colors.white54 : Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != albumName) {
                provider.renameAlbum(albumName, newName);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAlbumConfirm(
      BuildContext context, AppRiverpod provider, String albumName, bool hc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hc ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text('حذف الألبوم؟',
                style: TextStyle(
                    color: hc ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 16,
                color: hc ? Colors.white70 : Colors.black87,
                height: 1.5),
            children: [
              const TextSpan(text: 'هل أنت متأكد من حذف ألبوم '),
              TextSpan(
                text: '"$albumName"',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const TextSpan(
                  text: '؟\nسيتم حذف الألبوم وكل الصور بداخله نهائياً.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteAlbum(albumName);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context, AppRiverpod provider) {
    final TextEditingController controller = TextEditingController();
    bool hc = provider.isHighContrast;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: hc ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إنشاء ألبوم جديد',
            style: TextStyle(
                color: hc ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: hc ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'اسم الألبوم (مثال: رحلة الصيف)',
            hintStyle: TextStyle(color: hc ? Colors.white54 : Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF6C63FF), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createAlbum(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('إنشاء',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyNote(AppRiverpod provider) {
    final hc = provider.isHighContrast;

    final familyMessages = provider.memoriesList
        .where((m) =>
            m.category == 'أسرة' &&
            m.type == 'text' &&
            ((m.content?.trim().isNotEmpty ?? false) ||
                m.title.trim().startsWith('رسالة')))
        .toList();
    final hasCustomMessage = familyMessages.isNotEmpty;
    final previewMessages = familyMessages.take(2).toList();

    return AnimatedBuilder(
      animation: Listenable.merge([_noteController, _floatController]),
      builder: (context, child) {
        final opacity = _noteController.value;
        final entryOffset = (1 - _noteController.value) * 12.0;
        final floatOffset = _noteController.isCompleted
            ? (Curves.easeInOut.transform(_floatController.value) * 6.0 - 3.0)
            : 0.0;
        return Transform.translate(
          offset: Offset(0, entryOffset + floatOffset),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasCustomMessage
            ? () => _showFamilyMessagesSheet(context, familyMessages, hc)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: hc ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hc
                  ? const Color(0xFFfbbf24)
                  : const Color(0xFFFFF7ED), // Subtle warm borders
              width: hc ? 2.0 : 1.5,
            ),
            boxShadow: hc
                ? [
                    BoxShadow(
                      color: const Color(0xFFfbbf24).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    // Luxury Neumorphic dual shadows for absolute 3D realism
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium 3D Orange-Pink Gradient side tab
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Core content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Row with Expanded title to prevent overflow (without icon)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              previewMessages.length > 1
                                  ? 'رسائل مكتوبة من الأسرة'
                                  : 'رسالة مكتوبة من الأسرة',
                              style: TextStyle(
                                fontSize: 16.5, // Slightly smaller and elegant
                                fontWeight: FontWeight.w800, // Balanced bold
                                fontFamily: 'Cairo',
                                color: hc
                                    ? const Color(0xFFfbbf24)
                                    : const Color(0xFF4F46E5), // Premium Indigo
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hc
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(
                                      0xFFF5F3FF), // Coordinated soft purple tint
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hc
                                    ? Colors.transparent
                                    : const Color(0xFFDDD6FE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'العائلة',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: hc
                                    ? Colors.white70
                                    : const Color(0xFF7C3AED), // Muted Violet
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (hasCustomMessage)
                        ...previewMessages.map(
                          (message) => _buildFamilyMessagePreview(message, hc),
                        )
                      else
                        Text(
                          'لا توجد رسائل مكتوبة من الأسرة حتى الآن',
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'Cairo',
                            height: 1.6,
                            fontWeight: FontWeight.bold,
                            color: hc ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      if (familyMessages.length > 2) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'عرض كل الرسائل (${familyMessages.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                              color: hc
                                  ? const Color(0xFFfbbf24)
                                  : const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyMessagePreview(MemoryItem message, bool hc,
      {bool expanded = false}) {
    final sender = _familyMessageSender(message);
    final text = _familyMessageText(message);
    final date = message.date.trim().isEmpty ? 'اليوم' : message.date.trim();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: expanded ? 10 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 14 : 12,
        vertical: expanded ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color:
            hc ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hc
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFEDE9FE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$text"',
            maxLines: expanded ? null : 2,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: expanded ? 17 : 16,
              fontFamily: 'Cairo',
              height: 1.55,
              fontWeight: FontWeight.w800,
              color: hc ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFEC4899), size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'من: $sender',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: hc ? Colors.white70 : const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: hc ? Colors.white54 : const Color(0xFF8B5CF6),
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: hc ? Colors.white54 : const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFamilyMessagesSheet(
    BuildContext context,
    List<MemoryItem> messages,
    bool hc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: hc ? const Color(0xFF111827) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: hc
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'رسائل الأسرة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: hc ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: hc
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${messages.length} رسائل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: hc ? Colors.white70 : const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: hc ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildFamilyMessagePreview(
                        messages[index],
                        hc,
                        expanded: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _familyMessageText(MemoryItem message) {
    final raw = (message.content?.trim().isNotEmpty ?? false)
        ? message.content!.trim()
        : message.title.trim();
    return raw.replaceFirst(RegExp(r'^من[:：]\s*.+?\n+'), '').trim();
  }

  String _familyMessageSender(MemoryItem message) {
    final contentSender =
        RegExp(r'^من[:：]\s*(.+?)\n').firstMatch(message.content ?? '');
    if (contentSender != null) {
      final sender = _cleanFamilySender(contentSender.group(1) ?? '');
      if (sender.isNotEmpty) return sender;
    }

    final titleSender = RegExp(r'^رسالة(?:\s+مكتوبة|\s+صوتية)?\s+من\s+(.+)$')
        .firstMatch(message.title.trim());
    if (titleSender != null) {
      final sender = _cleanFamilySender(titleSender.group(1) ?? '');
      if (sender.isNotEmpty) return sender;
    }

    return 'العائلة';
  }

  String _cleanFamilySender(String value) {
    return value
        .replaceAll('❤️', '')
        .replaceAll('❤', '')
        .replaceAll('✉️', '')
        .replaceAll('✉', '')
        .replaceAll('🎤', '')
        .trim();
  }
}
