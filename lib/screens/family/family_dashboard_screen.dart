import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart' as file_picker_lib;
import '../../config/api_config.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'visit_booking_screen.dart';
import 'care_report_detail_screen.dart';
import 'resident_id_screen.dart';
import 'family_bridge_screen.dart';
import 'family_activities_screen.dart';
import '../../widgets/taptaba_scaffold.dart';
import '../../widgets/app_popup_notification.dart';
import '../../widgets/authenticated_network_image.dart';
import '../chat/family_resident_chat_screen.dart';
import '../elderly/widgets/video_call_overlay.dart';

class FamilyDashboardScreen extends ConsumerStatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  ConsumerState<FamilyDashboardScreen> createState() =>
      _FamilyDashboardScreenState();
}

class _FamilyMedicationStatus {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  const _FamilyMedicationStatus({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
  });
}

class _FamilyDashboardScreenState extends ConsumerState<FamilyDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showMedicationDoneAnimation = false;
  bool _isGeneratingUpdate = false;
  bool _updateInsufficient = false;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late List<Animation<double>> _fadeAnimations;
  Timer? _callPollTimer;
  Timer? _medicationVisibilityTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    _fadeAnimations = List.generate(10, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appRiverpod).loadMessageInbox();
      // بدء الـ polling للمكالمات الواردة كل 5 ثواني
      _callPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) ref.read(appRiverpod).refreshActiveVideoCalls();
      });
      _medicationVisibilityTimer =
          Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && _selectedIndex == 0) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _callPollTimer?.cancel();
    _medicationVisibilityTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final showHero = _selectedIndex == 0;

    return TaptabaScaffold(
      title: 'ونس',
      titleColor: const Color(0xFFea580c),
      overrideRole: 'عائلة',
      useNestedScrollView: true,
      sliverHeader: showHero ? _buildHero(provider) : null,
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBodyAnimatedBackground()),
          _selectedIndex == 0
              ? _buildHomeView(provider)
              : _selectedIndex == 1
                  ? _buildCareView(provider)
                  : _selectedIndex == 2
                      ? _buildVisitsView(provider)
                      : _buildBillingView(provider),
          if (_showMedicationDoneAnimation) _buildMedicationDoneOverlay(),
          if (provider.isIncomingCall) _buildIncomingCallBanner(provider),
          if (provider.isVideoCallActive) const VideoCallOverlay(),
        ],
      ),
    );
  }

  Widget _buildHero(AppRiverpod provider) {
    final residentId =
        provider.backendResidentId ?? provider.currentAccount?.linkedResidentId;
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'المقيم';
    final canStartResidentChat = residentId != null && residentId.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFea580c), Color(0xFFf97316), Color(0xFFfb923c)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'مرحباً ${provider.currentAccount?.name ?? 'أهلاً بك'} 👋',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Text('آخر زيارة: اليوم',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Spacer(),
                      if (canStartResidentChat)
                        _buildChatHeaderButton(
                            provider, residentId, residentName, context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildWellnessPulse(provider),
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
              top: -60 + (30 * _floatController.value),
              right: -50 + (20 * _floatController.value),
              child: _buildRealisticOrb(220, [
                const Color(0xFFfb923c).withValues(alpha: 0.35),
                const Color(0xFFea580c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            // Orb 2 - Bottom Left
            Positioned(
              bottom: -40 + (40 * (1 - _floatController.value)),
              left: -50 + (25 * _floatController.value),
              child: _buildRealisticOrb(190, [
                const Color(0xFFfdba74).withValues(alpha: 0.3),
                const Color(0xFFf97316).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
            // Orb 3 - Center Left
            Positioned(
              top: 50 + (40 * sin(_floatController.value * pi)),
              left: 20 + (50 * cos(_floatController.value * pi)),
              child: _buildRealisticOrb(110, [
                const Color(0xFFfed7aa).withValues(alpha: 0.25),
                const Color(0xFFfb923c).withValues(alpha: 0.08),
                Colors.transparent,
              ]),
            ),
            // Orb 4 - Center Right
            Positioned(
              bottom: 40 + (30 * _floatController.value),
              right: 80 + (20 * _floatController.value),
              child: _buildRealisticOrb(130, [
                const Color(0xFFea580c).withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ]),
            ),
            // Orb 5 - Top Left
            Positioned(
              top: -30 + (20 * (1 - _floatController.value)),
              left: 100 + (40 * _floatController.value),
              child: _buildRealisticOrb(95, [
                const Color(0xFFfb923c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            // Orb 6 - Near Pulse (Center)
            Positioned(
              top: 140 - (30 * _floatController.value),
              right: 40 + (60 * _floatController.value),
              child: _buildRealisticOrb(85, [
                const Color(0xFFfdba74).withValues(alpha: 0.12),
                Colors.transparent,
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController]),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.05 +
                  (50 * _floatController.value),
              left: -50 + (30 * _floatController.value),
              child: _buildRealisticOrb(300, [
                const Color(0xFFea580c).withValues(alpha: 0.25),
                const Color(0xFFfdba74).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.7 +
                  (50 * (1 - _floatController.value)),
              right: -50 + (30 * _floatController.value),
              child: _buildRealisticOrb(250, [
                const Color(0xFFf97316).withValues(alpha: 0.25),
                const Color(0xFFfed7aa).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4 +
                  (40 * sin(_floatController.value * pi)),
              left: MediaQuery.of(context).size.width * 0.05 +
                  (40 * cos(_floatController.value * pi)),
              child: _buildRealisticOrb(150, [
                const Color(0xFFea580c).withValues(alpha: 0.20),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2 +
                  (30 * _floatController.value),
              right: MediaQuery.of(context).size.width * 0.05 +
                  (40 * (1 - _floatController.value)),
              child: _buildRealisticOrb(180, [
                const Color(0xFFf97316).withValues(alpha: 0.20),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.8 +
                  (60 * _floatController.value),
              left: MediaQuery.of(context).size.width * 0.1 +
                  (30 * _floatController.value),
              child: _buildRealisticOrb(200, [
                const Color(0xFFfdba74).withValues(alpha: 0.18),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3 +
                  (40 * _floatController.value),
              right: MediaQuery.of(context).size.width * 0.2 +
                  (30 * (1 - _floatController.value)),
              child: _buildRealisticOrb(140, [
                const Color(0xFFea580c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.6 +
                  (50 * sin(_floatController.value * pi)),
              left: MediaQuery.of(context).size.width * 0.3 +
                  (40 * cos(_floatController.value * pi)),
              child: _buildRealisticOrb(160, [
                const Color(0xFFf97316).withValues(alpha: 0.15),
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
            // Base Gradient
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: baseColors,
                ),
              ),
            ),
            // Rotating Effect
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
            // Glassy Reflection
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

  Widget _buildWellnessPulse(AppRiverpod provider) {
    return FadeTransition(
      opacity: _fadeAnimations[1],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: ref.watch(appRiverpod).compliancePercentage / 100,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                      color: Colors.white24, shape: BoxShape.circle),
                  child: const Center(
                      child: Text('مح',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold))),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'نبض العافية — ${provider.residentFiles.isNotEmpty ? provider.residentFiles.first.name : 'المقيم'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                          provider.currentMood == 'happy'
                              ? 'سعيد ومبتهج 😊'
                              : provider.currentMood == 'calm'
                                  ? 'هادئ ومستقر 😌'
                                  : provider.currentMood == 'tired'
                                      ? 'يحتاج للراحة 😴'
                                      : provider.currentMood == 'active'
                                          ? 'نشيط وحيوي 🔥'
                                          : 'مستقر ومطمئن',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: provider.currentMood == 'tired'
                                  ? const Color(0xFFfbbf24)
                                  : const Color(0xFF4ade80),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: (provider.currentMood == 'tired'
                                            ? const Color(0xFFfbbf24)
                                            : const Color(0xFF4ade80))
                                        .withValues(alpha: 0.6),
                                    blurRadius: 4 + _pulseController.value * 8,
                                    spreadRadius: _pulseController.value * 4)
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildMiniBadge('🥣 فطر جيداً', const Color(0xFFfef3c7)),
                      const SizedBox(width: 6),
                      _buildMiniBadge('😴 نوم هادئ', const Color(0xFFdbeafe)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // ignore: unused_element
  Widget _buildTabs() {
    final tabs = [
      {'lbl': 'نظرة عامة', 'icon': Icons.dashboard_outlined},
      {'lbl': 'الرعاية', 'icon': Icons.favorite_border_rounded},
      {'lbl': 'الزيارات', 'icon': 'assets/icons/calendar.png'},
      {'lbl': 'الفواتير', 'icon': Icons.account_balance_wallet_outlined},
    ];

    return Container(
      height: 48,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9)))),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isAct = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isAct
                              ? const Color(0xFFea580c)
                              : Colors.transparent,
                          width: 2.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tabs[index]['lbl'] as String,
                        style: TextStyle(
                            color: isAct
                                ? const Color(0xFFea580c)
                                : const Color(0xFF94a3b8),
                            fontSize: 10,
                            fontWeight:
                                isAct ? FontWeight.bold : FontWeight.w500)),
                    const SizedBox(width: 4),
                    Icon(tabs[index]['icon'] as IconData,
                        size: 14,
                        color: isAct
                            ? const Color(0xFFea580c)
                            : const Color(0xFF94a3b8)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- VIEWS ---

  String _residentPresenceLabel(SpecialistResidentFile? resident) {
    return 'حالة المقيم ${resident?.isOnline == true ? 'متصل' : 'غير متصل'}';
  }

  Widget _buildChatHeaderButton(AppRiverpod provider, String residentId,
      String residentName, BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.chat_bubble_outline_rounded,
            color: Colors.white, size: 22),
      ),
      itemBuilder: (context) {
        // Show all residents as chat options
        return provider.residentFiles.map((resident) {
          return PopupMenuItem<String>(
            value: resident.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFfff7ed),
                  child: Text(
                    resident.name.isNotEmpty ? resident.name[0] : '؟',
                    style: const TextStyle(
                        color: Color(0xFFea580c),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    resident.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (selectedResidentId) {
        final selectedResident = provider.residentFiles
            .firstWhere((r) => r.id == selectedResidentId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyResidentChatScreen(
              otherUserId: selectedResidentId,
              otherUserName: selectedResident.name,
              otherUserRole: _residentPresenceLabel(selectedResident),
              residentId: selectedResidentId,
            ),
          ),
        ).then((_) => provider.loadMessageInbox());
      },
    );
  }

  // --- VIEWS ---

  Widget _buildHomeView(AppRiverpod provider) {
    final medicationReminder = provider.familyMedicationReminder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHealthMetricsGrid(provider),
          const SizedBox(height: 24),
          _buildFamilyAIUpdateCard(provider)
              .animate(delay: 80.ms)
              .fadeIn(duration: 350.ms)
              .slideY(
                  begin: 0.06, end: 0, duration: 350.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),
          _buildFamilyMessageCard(provider, context),
          const SizedBox(height: 24),
          _buildGamificationCard(provider, context),
          const SizedBox(height: 24),
          _buildFamilyActivitiesCard(provider, context),
          const SizedBox(height: 24),
          _buildMemoryWall(provider),
          const SizedBox(height: 24),
          if (medicationReminder != null) ...[
            _buildNextmedCard(provider, medicationReminder),
            const SizedBox(height: 20),
          ],
          _buildUpcomingVisit(provider),
          const SizedBox(height: 24),
          _buildReviewsCard(provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFamilyMessageCard(AppRiverpod provider, BuildContext context) {
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'المقيم';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_chat_unread_rounded,
                    color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رسائل الأسرة للمقيم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'اكتب رسالة تظهر في ذكريات $residentName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTextMessageDialog(context, provider),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('رسالة مكتوبة'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showVoiceRecordDialog(context, provider),
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('رسالة صوتية'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyAIUpdateCard(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تحديث الأسبوع الذكي',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('ملخص مدعوم بالذكاء الاصطناعي لحالة والدك',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isGeneratingUpdate)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    SizedBox(height: 10),
                    Text('جارٍ توليد التحديث الأسبوعي...',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            )
          else if (provider.latestFamilyUpdate.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _isGeneratingUpdate = true;
                      _updateInsufficient = false;
                    });
                    try {
                      await provider.fetchFamilyUpdate();
                      if (mounted && provider.latestFamilyUpdate.isEmpty) {
                        setState(() => _updateInsufficient = true);
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('فشل توليد التحديث، حاول مجدداً',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isGeneratingUpdate = false);
                    }
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('توليد التحديث الأسبوعي بالذكاء الاصطناعي',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
                if (_updateInsufficient) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0f9ff),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF7dd3fc), width: 1),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF0284c7), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'نحتاج بيانات أكثر لإنشاء التحديث. '
                            'ستظهر بعد تراكم المعلومات اليومية كالأدوية والأنشطة والملاحظات.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0369a1),
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    provider.latestFamilyUpdate,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF334155), height: 1.6),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    setState(() => _isGeneratingUpdate = true);
                    try {
                      await provider.fetchFamilyUpdate();
                    } finally {
                      if (mounted) setState(() => _isGeneratingUpdate = false);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('تحديث مجدداً',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFEA580C).withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Text('⭐', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقييم الخدمات',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('رأيك يهمنا لتحسين جودة الرعاية لوالدك.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _reviewButton(
                      'الأخصائي', () => _showReviewDialog('specialist'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _reviewButton(
                      'الممرض', () => _showReviewDialog('nurse'))),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _reviewButton('الدار', () => _showReviewDialog('home'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  void _showReviewDialog(String toRole) {
    double rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
              'تقييم ${toRole == 'specialist' ? 'الأخصائي' : toRole == 'nurse' ? 'الممرض' : 'الدار'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(index < rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFEAB308)),
                    onPressed: () => setState(() => rating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'اكتب رأيك هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final provider = ref.read(appRiverpod);
                provider.addReview(Review(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  fromRole: 'family',
                  fromName: provider.currentAccount?.name ?? 'أحد أفراد الأسرة',
                  toRole: toRole,
                  rating: rating,
                  comment: commentController.text,
                  date: DateTime.now().toString(),
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم إرسال تقييمك بنجاح! ⭐'),
                      backgroundColor: Color(0xFFEA580C)),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C)),
              child: const Text('إرسال', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryWall(AppRiverpod provider) {
    final residentId = provider.currentAccount?.linkedResidentId ??
        (provider.residentFiles.isNotEmpty
            ? provider.residentFiles.first.id
            : null);
    final moments = provider.memoryWallMoments(residentId: residentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: const Color(0xFF0ea5e9),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('حائط الذكريات',
                style: TextStyle(
                    color: Color(0xFF1f2937),
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FamilyBridgeScreen())),
              child: const Text('عرض الكل / إضافة',
                  style: TextStyle(
                      color: Color(0xFF0ea5e9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (moments.isEmpty)
          Container(
            height: 132,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF0284C7), size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'لا توجد صور عائلية بعد',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اضغط عرض الكل / إضافة لمشاركة أول صورة.',
                        textAlign: TextAlign.right,
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: moments.length,
              itemBuilder: (context, i) {
                final m = moments[i];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFf1f5f9)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          child: _buildMemoryMomentImage(
                            m.imageUrl,
                            fallbackPath: m.fallbackPath,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_shouldShowMemoryMomentTitle(
                                  m.activityTitle)) ...[
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
                              const Spacer(),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => provider.addAppreciation(m.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFfff1f2),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Row(
                                        children: [
                                          Text('${m.appreciations}',
                                              style: const TextStyle(
                                                  color: Color(0xFFe11d48),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.favorite,
                                              color: Color(0xFFe11d48),
                                              size: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text('ممتنـون ❤️',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF64748b))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMemoryMomentImage(String imageUrl, {String? fallbackPath}) {
    final paths = _memoryImageCandidates(imageUrl, fallbackPath);
    if (paths.isEmpty) return _buildMemoryImageFallback();
    return _buildMemoryImageFromCandidates(paths);
  }

  Widget _buildMemoryImageFromCandidates(List<String> paths, {int index = 0}) {
    if (index >= paths.length) return _buildMemoryImageFallback();
    final path = paths[index];
    final fallback = _buildMemoryImageFromCandidates(paths, index: index + 1);
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

    final resolvedUrl = _resolveMemoryImageUrl(path);
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

  List<String> _memoryImageCandidates(String imageUrl, String? fallbackPath) {
    final seen = <String>{};
    return [imageUrl, fallbackPath]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .where((value) => seen.add(value))
        .toList();
  }

  bool _shouldShowMemoryMomentTitle(String title) {
    final clean = title.trim();
    return clean.isNotEmpty &&
        clean != 'صورة عائلية جديدة' &&
        clean != 'لحظة عائلية' &&
        clean != 'صورة جديدة';
  }

  String _resolveMemoryImageUrl(String raw) {
    if (raw.startsWith('/') && !raw.startsWith('//')) {
      return '${ApiConfig.baseUrl}$raw';
    }
    return raw;
  }

  Widget _buildMemoryImageFallback() {
    return Container(
      color: const Color(0xFFE0F2FE),
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: Color(0xFF0284C7), size: 30),
      ),
    );
  }

  Widget _buildGamificationCard(AppRiverpod provider, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFEF08A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE047)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFEAB308).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE047),
                  shape: BoxShape.circle,
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إنجازات والدك الصحية',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF854D0E))),
                    Text('أتم أخذ أدويته في موعدها وحصل على ١٠ نقاط! 🎉',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFFA16207))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => _showEncouragementSheet(provider, context),
              icon: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 18),
              label: const Text('إرسال تشجيع أو هدية',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyActivitiesCard(
      AppRiverpod provider, BuildContext context) {
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'المقيم العزيز';

    // فلترة أنشطة اليوم النشطة
    final todayActivities = provider.activities
        .where((a) => a.dayTag == 'اليوم' && a.status == 'active')
        .toList();
    final joinedCount = todayActivities
        .where((a) => provider.isFamilyParticipating(a.id))
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf0fdf4), Color(0xFFd1fae5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6ee7b7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF34d399),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'الأنشطة العائلية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065f46),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'نشاط مشترك',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      joinedCount > 0
                          ? 'أنت مشارك في $joinedCount من الأنشطة العائلية اليوم'
                          : '$residentName بانتظار مشاركتك اللطيفة اليوم',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF065f46),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'نشر الأخصائي الاجتماعي أنشطة اليوم. مشاركتك تخفف عنه وتصنع يومه بالكامل. هل تسجل حضورك معه الآن؟',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF065f46),
              fontWeight: FontWeight.w500,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FamilyActivitiesScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'تصفح ومشاركة الأنشطة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEncouragementSheet(AppRiverpod provider, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 24),
            const Text('شجّع والدك ❤️',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const Text('اختر طريقة لإرسال الدعم العاطفي لوالدك ليراه فوراً.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showVoiceRecordDialog(context, provider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.mic_rounded,
                              color: Color(0xFF0EA5E9), size: 36),
                          SizedBox(height: 8),
                          Text('رسالة صوتية',
                              style: TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showTextMessageDialog(context, provider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFEF08A)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFFEAB308), size: 36),
                          SizedBox(height: 8),
                          Text('رسالة نصية',
                              style: TextStyle(
                                  color: Color(0xFFA16207),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecordDialog(BuildContext context, AppRiverpod provider) {
    bool isRecording = false;
    int seconds = 0;
    Timer? timer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تسجيل رسالة صوتية', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                size: 64,
                color: isRecording ? Colors.red : Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                isRecording
                    ? 'جارٍ التسجيل... $secondsث'
                    : 'اضغط للبدء بالتسجيل',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                timer?.cancel();
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isRecording) {
                  setState(() {
                    isRecording = true;
                  });
                  timer = Timer.periodic(const Duration(seconds: 1), (t) {
                    setState(() {
                      seconds++;
                    });
                  });
                } else {
                  timer?.cancel();
                  Navigator.pop(context);
                  provider.sendEncouragementMessage('voice');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم إرسال رسالتك الصوتية بنجاح 🎤✨'),
                        backgroundColor: Color(0xFF0EA5E9)),
                  );
                }
              },
              child: Text(isRecording ? 'إيقاف وإرسال' : 'بدء التسجيل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextMessageDialog(BuildContext context, AppRiverpod provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرسال رسالة تشجيعية', textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب رسالتك هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFea580c)),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.sendEncouragementMessage('text',
                    text: controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم إرسال رسالتك بنجاح ✉️✨'),
                      backgroundColor: Color(0xFFEAB308)),
                );
              }
            },
            child: const Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricsGrid(AppRiverpod provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: const Color(0xFFea580c),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('مؤشرات الحالة اليوم',
                style: TextStyle(
                    color: Color(0xFF1f2937),
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4),
          itemCount: provider.familyHealthMetrics.length,
          itemBuilder: (context, i) {
            final m = provider.familyHealthMetrics[i];
            return GestureDetector(
              onTap: () => _showMetricDetailsSheet(context, m),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFf1f5f9)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(m.label,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF000000),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 4),
                        _buildTrendIcon(m.trend),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text('${(m.value * 100).toInt()}%',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF000000),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 4),
                        _buildMetricBadge(m.status),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showMetricDetailsSheet(BuildContext context, dynamic m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('تفاصيل ${m.label}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildHistoryItem(
                'اليوم',
                '${(((m.history as List).isNotEmpty ? m.history[0] : m.value) * 100).toInt()}%',
                m.status),
            _buildHistoryItem(
                'أمس',
                '${(((m.history as List).length > 1 ? m.history[1] : m.value) * 100).toInt()}%',
                m.status),
            _buildHistoryItem(
                'قبل يومين',
                '${(((m.history as List).length > 2 ? m.history[2] : m.value) * 100).toInt()}%',
                m.status),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String day, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              _buildMetricBadge(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String status) {
    Color bg = const Color(0xFFf1f5f9);
    Color fg = const Color(0xFF64748b);
    String label = 'مستقر';

    if (status == 'critical') {
      bg = const Color(0xFFfee2e2);
      fg = const Color(0xFFef4444);
      label = 'تنبيه';
    } else if (status == 'good') {
      bg = const Color(0xFFdcfce7);
      fg = const Color(0xFF16a34a);
      label = 'ممتاز';
    } else if (status == 'medium') {
      bg = const Color(0xFFfef3c7);
      fg = const Color(0xFFd97706);
      label = 'جيد';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildTrendIcon(String trend) {
    dynamic icon = Icons.trending_flat_rounded;
    Color color = const Color(0xFF64748b);

    if (trend == 'up') {
      icon = Icons.trending_up_rounded;
      color = const Color(0xFF10b981);
    } else if (trend == 'down') {
      icon = Icons.trending_down_rounded;
      color = const Color(0xFFef4444);
    }

    return Icon(icon, color: color, size: 18);
  }

  Widget _buildNextmedCard(AppRiverpod provider, Medication medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFeff6ff), Color(0xFFdbeafe)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFbfdbfe)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_liquid_rounded,
              color: Color(0xFF3b82f6), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الجرعة القادمة: ${medication.name}',
                    style: const TextStyle(
                        color: Color(0xFF1e3a8a),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text(
                    'موعد ${medication.timeOfDay} — ${medication.timeDescription}',
                    style: const TextStyle(
                        color: Color(0xFF3b82f6), fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              ref.read(appRiverpod).sendFamilyMedicationReminder(medication);

              setState(() {
                _showMedicationDoneAnimation = true;
              });

              await Future.delayed(const Duration(seconds: 2));

              if (mounted) {
                setState(() {
                  _showMedicationDoneAnimation = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('تذكير',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingVisit(AppRiverpod provider) {
    final upcomingVisits =
        provider.familyVisits.where((v) => v.status == 'upcoming').toList();
    if (upcomingVisits.isEmpty) return const SizedBox.shrink();

    final visit = upcomingVisits.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('زيارتك القادمة',
                  style: TextStyle(
                      color: Color(0xFF1f2937),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFdcfce7),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('مؤكدة',
                    style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildVisitInfo('assets/icons/calendar.png', visit.date),
              const SizedBox(width: 20),
              _buildVisitInfo(Icons.access_time_filled, visit.time),
              const Spacer(),
              const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFf3f4f6),
                  child: Text('س',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0f172a)))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VisitBookingScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFfff7ed),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFfed7aa))),
                    child: const Center(
                        child: Text('تعديل الموعد',
                            style: TextStyle(
                                color: Color(0xFFea580c),
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancelVisit(visit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFb91c1c),
                    side: const BorderSide(color: Color(0xFFfecaca)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('إلغاء اللقاء',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelVisit(FamilyVisit visit) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء اللقاء', textAlign: TextAlign.right),
        content: Text(
          'هل تريد إلغاء ${visit.type == 'video' ? 'مكالمة الفيديو' : 'لقاء مودة'} يوم ${visit.date} الساعة ${visit.time}؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFdc2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('إلغاء اللقاء'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;
    final provider = ref.read(appRiverpod);
    final ok = await provider.cancelFamilyVisit(visit.id);
    if (!mounted) return;
    showAppPopupNotification(
      context,
      message: ok
          ? 'تم إلغاء اللقاء ونقله إلى السجل السابق'
          : provider.backendSyncError ?? 'تعذر إلغاء اللقاء',
      type: ok
          ? AppPopupNotificationType.success
          : AppPopupNotificationType.error,
      duration: const Duration(seconds: 3),
    );
  }

  Widget _buildVisitInfo(dynamic icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text,
            style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 12,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        icon is IconData
            ? Icon(icon, size: 14, color: const Color(0xFF334155))
            : Image.asset(icon as String,
                width: 14, height: 14, color: const Color(0xFF334155)),
      ],
    );
  }

  Widget _buildCareView(AppRiverpod provider) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('سجل الأدوية اليوم'),
        const SizedBox(height: 16),
        ...provider.medications.map((m) => _buildCareLogCard(m)),
        const SizedBox(height: 32),
        _buildSectionHeader('آخر التقارير الطبية'),
        const SizedBox(height: 16),
        ...provider.careReports.map((r) => _buildReportCard(
            r.title, r.date, r.summary, const Color(0xFF6366f1), r)),
      ],
    );
  }

  Widget _buildCareLogCard(Medication m) {
    final status = _familyMedicationStatus(m);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF000000))),
                const SizedBox(height: 2),
                Text('${m.dosage} · ${m.timeDescription}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1e293b),
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 44,
            decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(10)),
            child:
                Center(child: Icon(status.icon, color: status.color, size: 22)),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 82),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: status.backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: status.borderColor),
            ),
            child: Text(
              status.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: status.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _FamilyMedicationStatus _familyMedicationStatus(Medication m) {
    if (m.isTaken && m.isElderlyConfirmed) {
      return const _FamilyMedicationStatus(
        label: 'تم الأخذ',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF059669),
        backgroundColor: Color(0xFFecfdf5),
        borderColor: Color(0xFFbbf7d0),
      );
    }
    if (m.isElderlyConfirmed && !m.isTaken) {
      return const _FamilyMedicationStatus(
        label: 'بانتظار الممرض',
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFF0284c7),
        backgroundColor: Color(0xFFe0f2fe),
        borderColor: Color(0xFFbae6fd),
      );
    }
    if (m.isSkipped) {
      return const _FamilyMedicationStatus(
        label: 'تم التجاوز',
        icon: Icons.block_rounded,
        color: Color(0xFF64748b),
        backgroundColor: Color(0xFFf8fafc),
        borderColor: Color(0xFFe2e8f0),
      );
    }
    if (m.isMissed) {
      return const _FamilyMedicationStatus(
        label: 'فاتت الجرعة',
        icon: Icons.error_rounded,
        color: Color(0xFFdc2626),
        backgroundColor: Color(0xFFfef2f2),
        borderColor: Color(0xFFfecaca),
      );
    }
    return const _FamilyMedicationStatus(
      label: 'قيد المتابعة',
      icon: Icons.pending_actions_rounded,
      color: Color(0xFFea580c),
      backgroundColor: Color(0xFFfff7ed),
      borderColor: Color(0xFFfed7aa),
    );
  }

  Widget _buildReportCard(
      String title, String date, String excerpt, Color col, CareReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFf1f5f9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: col, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              Text(date,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            excerpt,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CareReportDetailScreen(report: report))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.arrow_back_ios, size: 12, color: Color(0xFFea580c)),
                SizedBox(width: 4),
                Text('عرض التقرير الكامل',
                    style: TextStyle(
                        color: Color(0xFFea580c),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsView(AppRiverpod provider) {
    return Column(
      children: [
        _buildVisitsHeader(),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: const Color(0xFFea580c),
                  unselectedLabelColor: const Color(0xFF94a3b8),
                  indicatorColor: const Color(0xFFea580c),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(
                        child: Text(
                            'الزيارات القادمة (${provider.familyVisits.where((v) => v.status == 'upcoming' || v.status == 'pending').length})',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    const Tab(
                        child: Text('السجل السابق',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildVisitsList(
                        provider.familyVisits
                            .where((v) =>
                                v.status == 'upcoming' || v.status == 'pending')
                            .toList(),
                        isUpcoming: true,
                      ),
                      _buildVisitsList(
                        provider.familyVisits
                            .where((v) =>
                                v.status != 'upcoming' && v.status != 'pending')
                            .toList(),
                        isUpcoming: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitsHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VisitBookingScreen())),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFea580c), Color(0xFFf97316)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFea580c).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('جدولة لقاء مودة',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('اختر الوقت المناسب لرؤية أحبائك',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              SizedBox(width: 16),
              Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitsList(List<FamilyVisit> visits, {bool isUpcoming = true}) {
    if (visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFfff7ed),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFfed7aa), width: 2),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    size: 40, color: Color(0xFFea580c)),
              ),
              const SizedBox(height: 20),
              Text(
                isUpcoming ? 'لا توجد زيارات قادمة' : 'لا توجد زيارات سابقة',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              if (isUpcoming)
                const Text(
                  'جدّل زيارتك القادمة لأحبائك الآن',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF94a3b8)),
                ),
              if (isUpcoming) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VisitBookingScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('جدولة زيارة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFea580c),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: visits.length,
      itemBuilder: (context, i) => _buildVisitCard(visits[i]),
    );
  }

  Widget _buildVisitCard(FamilyVisit v) {
    bool isUpcoming = v.status == 'upcoming';
    bool canManage = v.status == 'upcoming' || v.status == 'pending';
    return GestureDetector(
      onTap: () => _showVisitDetailsModal(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFf1f5f9)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(v.type == 'physical' ? '🏠 لقاء مودة' : '📹 مكالمة فيديو',
                    style: const TextStyle(
                        color: Color(0xFF64748b),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildVisitBadge(v.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الزائر: ${v.visitorName}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b))),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildVisitInfo('assets/icons/calendar.png', v.date),
                          const SizedBox(width: 12),
                          _buildVisitInfo(Icons.access_time_rounded, v.time),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      v.type == 'physical'
                          ? Icons.people_alt_rounded
                          : Icons.videocam_rounded,
                      color: const Color(0xFFea580c)),
                ),
              ],
            ),
            if (canManage) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFf1f5f9)),
              const SizedBox(height: 10),
              if (isUpcoming && v.type == 'video' && v.zoomLink != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.videocam_rounded,
                        color: Colors.white, size: 18),
                    label: const Text('انضم للمكالمة',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _openZoomVisit(v.zoomLink!),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFfff7ed),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VisitBookingScreen())),
                      child: const Text('تعديل الموعد',
                          style: TextStyle(
                              color: Color(0xFFea580c),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFcbd5e1)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () => _confirmCancelVisit(v),
                      child: const Text('إلغاء اللقاء',
                          style: TextStyle(color: Color(0xFFb91c1c))),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVisitDetailsModal(FamilyVisit visit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'تفاصيل الزيارة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildVisitDetailRow('الزائر', visit.visitorName),
            _buildVisitDetailRow('التاريخ', visit.date),
            _buildVisitDetailRow('الوقت', visit.time),
            _buildVisitDetailRow(
              'النوع',
              visit.type == 'video' ? 'مكالمة فيديو' : 'زيارة حضورية',
            ),
            _buildVisitDetailRow('الحالة', _visitStatusLabel(visit.status)),
            if (visit.type == 'video') ...[
              const SizedBox(height: 8),
              if ((visit.zoomLink ?? '').trim().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openZoomVisit(visit.zoomLink!),
                    icon: const Icon(Icons.videocam_rounded,
                        color: Colors.white, size: 18),
                    label: const Text(
                      'دخول مكالمة Zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'رابط Zoom غير متاح حالياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFEA580C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openZoomVisit(String link) async {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildVisitDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  String _visitStatusLabel(String status) {
    if (status == 'upcoming') return 'قادمة';
    if (status == 'pending') return 'بانتظار التأكيد';
    if (status == 'completed') return 'مكتملة';
    if (status == 'cancelled') return 'ملغاة';
    return 'غير محدد';
  }

  Widget _buildVisitBadge(String status) {
    Color col = const Color(0xFF64748b);
    Color bg = const Color(0xFFf1f5f9);
    String label = 'غير محدد';
    if (status == 'upcoming') {
      col = const Color(0xFF1d4ed8);
      bg = const Color(0xFFdbeafe);
      label = 'قادمة';
    } else if (status == 'pending') {
      col = const Color(0xFF92400e);
      bg = const Color(0xFFfef3c7);
      label = 'بانتظار التأكيد';
    } else if (status == 'completed') {
      col = const Color(0xFF166534);
      bg = const Color(0xFFdcfce7);
      label = 'تمت';
    } else if (status == 'cancelled') {
      col = const Color(0xFFef4444);
      bg = const Color(0xFFfee2e2);
      label = 'ملغاة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style:
              TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBillingView(AppRiverpod provider) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildBillingSummary(provider),
        const SizedBox(height: 32),
        _buildSectionHeaderWithAction('الفواتير المتاحة', 'رؤية الكل'),
        const SizedBox(height: 16),
        ...provider.familyBills.map((b) => _buildBillCard(b)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBillingSummary(AppRiverpod provider) {
    final amount = provider.unpaidBillsAmount;
    final hasAmount = amount > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0f172a).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المستحقات الحالية',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 26),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasAmount
                ? '${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ج.م'
                : '٠ ج.م',
            style: const TextStyle(
                color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          if (hasAmount) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFea580c), Color(0xFFf97316)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFFea580c).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: () => _showPaymentSheet(provider),
                      child: const Text('ادفع الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري تجهيز وتحميل الفاتورة بصيغة PDF...'),
                      backgroundColor: Color(0xFF1e293b),
                    ),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child:
                        const Icon(Icons.download_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF34D399), size: 20),
                  SizedBox(width: 10),
                  Text('لا توجد مستحقات للدفع',
                      style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentSheet(AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFe2e8f0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('تأكيد الدفع',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                  'يرجى التحويل إلى أحد الحسابات التالية لإتمام عملية الدفع أو التبرع:',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                  'رقم الحساب البنكي (بنك مصر): 1234 5678 9012 3456\nأو عبر محفظة إلكترونية (فودافون كاش): 01012345678',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Color(0xFF1e293b), fontSize: 15, height: 1.5)),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '${provider.unpaidBillsAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ج.م',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b))),
                  const Text('إجمالي المبلغ المراد دفعه',
                      style: TextStyle(
                          color: Color(0xFF64748b),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('إرفاق صورة التحويل:',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                try {
                  final result = await file_picker_lib.FilePicker.platform
                      .pickFiles(type: file_picker_lib.FileType.image);
                  if (!context.mounted) return;
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرفاق الصورة بنجاح!')),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حدث خطأ أثناء اختيار الملف')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFcbd5e1), style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_rounded, color: Color(0xFFea580c)),
                    SizedBox(width: 8),
                    Text('اختر صورة الإيصال أو الإسكرين',
                        style: TextStyle(
                            color: Color(0xFFea580c),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFea580c),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                onPressed: () async {
                  Navigator.pop(context); // Close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال إثبات الدفع للإدارة للمراجعة!'),
                      backgroundColor: Color(0xFF16a34a),
                    ),
                  );
                },
                child: const Text('إرسال إثبات الدفع',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء العملية',
                  style: TextStyle(color: Color(0xFF94a3b8))),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _processPayment(AppRiverpod provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFea580c)),
                SizedBox(height: 24),
                Text('جاري معالجة الدفع...',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    await provider.clearUnpaidBills();
    if (!mounted) return;
    Navigator.pop(context);
    if (provider.backendSyncError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.backendSyncError!),
          backgroundColor: const Color(0xFFdc2626),
        ),
      );
    } else {
      _showSuccessPayment();
    }
  }

  void _showSuccessPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('تمت عملية الدفع بنجاح! شكراً لك.'),
          ],
        ),
        backgroundColor: const Color(0xFF16a34a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildSectionHeaderWithAction(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionHeader(title),
        Text(action,
            style: const TextStyle(
                color: Color(0xFFea580c),
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b))),
      ],
    );
  }

  Widget _buildBillCard(FamilyBill b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color:
                b.isPaid ? const Color(0xFFdcfce7) : const Color(0xFFf1f5f9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF000000))),
                Text(b.month,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                    b.isPaid
                        ? 'تم الدفع بنجاح'
                        : 'تاريخ الاستحقاق: ${b.dueDate}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: b.isPaid
                            ? const Color(0xFF166534)
                            : const Color(0xFFbe123c),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('${b.amount.toInt()} ج.م',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF000000))),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: b.isPaid
                    ? const Color(0xFFf0fdf4)
                    : const Color(0xFFfff1f2),
                shape: BoxShape.circle),
            child: Icon(
                b.isPaid ? Icons.check_rounded : Icons.priority_high_rounded,
                color: b.isPaid
                    ? const Color(0xFF16a34a)
                    : const Color(0xFFe11d48),
                size: 20),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.credit_card_rounded, color: Color(0xFF1e293b)),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visa **** 4242',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
              Text('بطاقة الدفع الأساسية',
                  style: TextStyle(color: Color(0xFF64748b), fontSize: 11)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_left_rounded, color: Color(0xFF94a3b8)),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _getMetricStatus(String s) {
    if (s == 'good') return 'جيد';
    if (s == 'medium') return 'مستقر';
    return 'منخفض';
  }

  // ignore: unused_element
  Color _getMetricBg(String s) {
    if (s == 'good') return const Color(0xFFd1fae5);
    if (s == 'medium') return const Color(0xFFfef3c7);
    return const Color(0xFFfee2e2);
  }

  // ignore: unused_element
  Color _getMetricFg(String s) {
    if (s == 'good') return const Color(0xFF065f46);
    if (s == 'medium') return const Color(0xFF92400e);
    return const Color(0xFF7f1d1d);
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_outlined, 'الرئيسية', 0),
          _buildNavItem(Icons.favorite_border_rounded, 'الرعاية', 1),
          _buildNavItem('assets/icons/calendar.png', 'الزيارات', 2),
          _buildNavItem(Icons.account_balance_wallet_outlined, 'الفواتير', 3),
          _buildNavItem(Icons.qr_code_scanner_rounded, 'الهوية', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(dynamic icon, String label, int index) {
    final isAct = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 4) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ResidentIdScreen()));
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon is IconData
              ? Icon(icon,
                  color:
                      isAct ? const Color(0xFFea580c) : const Color(0xFF475569),
                  size: 26)
              : Image.asset(icon as String,
                  color:
                      isAct ? const Color(0xFFea580c) : const Color(0xFF475569),
                  width: 26,
                  height: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color:
                      isAct ? const Color(0xFFea580c) : const Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: isAct ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildIncomingCallBanner(AppRiverpod provider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10b981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // أيقونة المتصل
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    child: Center(
                      child: Text(
                        provider.activeCallerInitials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // النص
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '📲 مكالمة فيديو واردة',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          provider.activeCallerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // رفض
                  GestureDetector(
                    onTap: () => provider.rejectCall(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.call_end_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // قبول
                  GestureDetector(
                    onTap: () => provider.acceptCall(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: Color(0xFF059669), size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationDoneOverlay() {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Lottie.asset('assets/animations/Meddone.json'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تم التذكير!',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  String _getFormattedCurrentDate() {
    final now = DateTime.now();
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    String day = _toArabicNumbers(now.day.toString());
    String year = _toArabicNumbers(now.year.toString());
    return '$day ${months[now.month - 1]} $year';
  }

  String _toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}
