import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../chat/family_resident_chat_screen.dart';
import 'cognitive_games_screen.dart';
import '../../models/app_models.dart'; // نماذج البيانات (Medication, User, etc.)
import 'package:lottie/lottie.dart';
// ويدجت رفيق الذكاء الاصطناعي
// حوار طلب الصلاحيات المخصص

class HomeScreen extends ConsumerStatefulWidget {
  // شاشة المسن الرئيسية
  const HomeScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<HomeScreen> createState() =>
      _HomeScreenState(); // إنشاء حالة الشاشة
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن المتعدد
  late AnimationController _bgController; // متحكم أنيميشن الخلفية المتحركة
  late AnimationController _pillController; // متحكم أنيميشن طفو حبة الدواء
  late AnimationController _ringController; // متحكم أنيميشن نبض الحلقة
  late AnimationController _starController; // متحكم أنيميشن قفز النجوم
  late AnimationController _glowController; // متحكم أنيميشن توهج الأزرار

  bool _showSuccessAnimation = false;
  String _successMessage = '';

  @override
  void initState() {
    // دالة التهيئة الأولية عند تشغيل الشاشة
    super.initState();

    // إعداد أنيميشن تدرج الخلفية (حركة بطيئة وهادئة)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // إعداد أنيميشن طفو حبة الدواء (حركة ترددية)
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // إعداد أنيميشن نبض الحلقة حول الزر
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // إعداد أنيميشن قفز النجوم عند كسب النقاط
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // إعداد أنيميشن توهج الأزرار للتنبيه
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pillController.dispose();
    _ringController.dispose();
    _starController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء واجهة الشاشة الرئيسية
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق
    return Stack(
      children: [
        _buildAnimatedBackground(),
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // مساحة إضافية في الأسفل
          child: Column(
            children: [
              // قسم الترحيب العلوي (Hero)
              _buildHero(provider),
              // تظهر بطاقة المزاج فقط مساءً (18:00–23:59) وإذا لم يسجّل بعد
              if (provider.currentMood.isEmpty && DateTime.now().hour >= 18)
                _buildMoodTracker(provider),

              // قسم البطاقات الرئيسية
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _buildMedicineCard(provider),
                    const SizedBox(height: 12),
                    _buildCognitiveGamesCard(provider, context),
                    const SizedBox(height: 12),
                    _buildPointsCard(
                        provider), // نقاط تظهر أولاً فوق جهات الاتصال
                    const SizedBox(height: 12),
                    _buildFamilyCard(provider, context),
                    const SizedBox(height: 12),
                    _buildComplaintCard(provider, context),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showSuccessAnimation) _buildCentralSuccessAnimation(),
      ],
    );
  }

  Widget _buildCentralSuccessAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      child: Lottie.asset(
        'assets/animations/Done.json',
        repeat: false,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          Future.delayed(composition.duration, () {
            if (mounted) {
              setState(() => _showSuccessAnimation = false);
            }
          });
        },
      ),
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.5 * value),
          child: Center(
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: child,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _successMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        )
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

  Widget _buildHero(AppRiverpod provider) {
    // بناء قسم الترحيب العلوي (الـ Hero)
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // تدرج أرجواني عميق
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a0533),
                Color(0xFF3730a3),
                Color(0xFF0f3460),
                Color(0xFF6C63FF),
              ],
            ),
          ),
          child: Stack(
            children: [
              // كرات ملونة متحركة في الخلفية (Blobs) للحيوية
              _buildBlob(180, const Color(0xFF6C63FF), -50, -50, 7),
              _buildBlob(130, const Color(0xFFf472b6), -35, 30, 9),
              _buildBlob(90, const Color(0xFF0ea5e9), 80, -10, 6),

              SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نص الترحيب الصباحي باسم المستخدم
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 20, left: 20, top: 15, bottom: 8),
                      child: FittedBox(
                        alignment: Alignment.centerRight,
                        fit: BoxFit.scaleDown,
                        child: Text(
                            'صباح الخير يا ${provider.currentUser.name} ',
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2)),
                      ),
                    ),

                    // أزرار الإجراء السريع (أدوية + نشاطات)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 24),
                      child: Row(
                        children: [
                          _buildQuickAction(
                            context,
                            icon: Icons.medication_rounded,
                            label: 'دوائي اليوم',
                            count: provider.todayMedications.length,
                            color: const Color(0xFF6C63FF),
                            onTap: () =>
                                ref.read(appRiverpod).setElderlyTabIndex(1),
                          ),
                          const SizedBox(width: 10),
                          _buildQuickAction(
                            context,
                            icon: Icons.self_improvement_rounded,
                            label: 'نشاط اليوم',
                            count: provider.activities
                                .where((a) => a.dayTag == 'اليوم')
                                .length,
                            color: const Color(0xFF3B82F6),
                            onTap: () =>
                                ref.read(appRiverpod).setElderlyTabIndex(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodTracker(AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text('طمنا عليك، كيف حالك اليوم؟ ✨',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _moodItem(provider, 'happy', '😊', 'سعيد'),
              _moodItem(provider, 'calm', '😌', 'هادئ'),
              _moodItem(provider, 'tired', '😴', 'متعب'),
              _moodItem(provider, 'active', '☀️', 'بخير'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moodItem(
      AppRiverpod provider, String mood, String emoji, String label) {
    return GestureDetector(
      onTap: () => provider.setMood(mood),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFede9fe)),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748b))),
        ],
      ),
    );
  }

  Widget _buildBlob(
      double size, Color color, double right, double top, double duration) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value * 2 * pi;
        final x = sin(t * (duration / 7)) * 8;
        final y = cos(t * (duration / 7)) * 10;

        return Positioned(
          left: right + x,
          top: top + y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.4),
            ),
            child: BackdropFilter(
              filter:
                  const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
              child: Container(color: Colors.transparent),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 11),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(AppRiverpod provider) {
    final nextMed = provider.nextMedication;

    // All doses confirmed by nurse — nothing left to show.
    if (nextMed == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'تم أخذ جميع أدوية اليوم ✓',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // Resident confirmed but nurse hasn't verified yet.
    if (nextMed.isElderlyConfirmed && !nextMed.isTaken) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextMed.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'في انتظار تأكيد الممرض',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('تم التأكيد',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Upcoming dose — resident hasn't confirmed yet.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الجرعة القادمة 💊',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              nextMed.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              nextMed.dosage,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              nextMed.timeDescription.isNotEmpty
                  ? nextMed.timeDescription
                  : 'بعد الغداء',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
            ),
            const SizedBox(height: 14),
            _buildTakeMedButton(provider, nextMed, context),
          ],
        ),
      ),
    );
  }

  Widget _buildTakeMedButton(
      AppRiverpod provider, Medication nextMed, BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.elderlyConfirmMedication(nextMed.id);
        setState(() {
          _successMessage = 'تم تسجيل أخذ الدواء';
          _showSuccessAnimation = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('أخذت الدواء ✓',
                style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(Icons.check_circle_outline_rounded,
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCognitiveGamesCard(AppRiverpod provider, BuildContext context) {
    final hc = provider.isHighContrast;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.extension_rounded,
                    color: Color(0xFF3B82F6), size: 28),
                SizedBox(width: 8),
                Text('ألعاب وتدريبات ذهنية 🧠',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6))),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'ألعاب مصممة بالذكاء الاصطناعي لتنشيط الذاكرة والتركيز بطريقة ممتعة.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (provider.cognitiveGameResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'آخر نتيجة: ${provider.cognitiveGameResult!.score}/10',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                                fontSize: 14),
                          ),
                          Text(
                            provider.cognitiveGameResult!.feedback,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CognitiveGamesScreen()),
                ),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(
                  provider.cognitiveGameResult == null
                      ? 'ابدأ اللعب'
                      : 'العب مرة أخرى',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(AppRiverpod provider, BuildContext context) {
    final bool hc = provider.isHighContrast;
    final members = provider.familyMembers;
    const gradients = [
      [Color(0xFFf472b6), Color(0xFFdb2777)],
      [Color(0xFF34d399), Color(0xFF059669)],
      [Color(0xFF818cf8), Color(0xFF4f46e5)],
      [Color(0xFFfbbf24), Color(0xFFd97706)],
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: hc ? 0.4 : 0.3),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: hc ? 0.25 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.phone_enabled_rounded,
                    color: Color(0xFF6C63FF), size: 26),
                const SizedBox(width: 8),
                Text('تواصل مع أحبائك 💜',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hc ? Colors.white : const Color(0xFF6C63FF))),
              ],
            ),
            const SizedBox(height: 14),
            // Members list — عمود واحد بدون GridView
            ...List.generate(members.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPerson(
                  members[i],
                  gradients[i % gradients.length]
                      .map((c) => c)
                      .toList(),
                  provider,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }


  Widget _buildPerson(
      FamilyMember member, List<Color> gradient, AppRiverpod provider) {
    final bool hc = provider.isHighContrast;
    final bool isOnline = member.isAvailable;
    final bool hasApp = member.userId != null && member.userId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hc ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF6C63FF).withValues(alpha: 0.25)
              : (hc ? const Color(0xFF333333) : const Color(0xFFF0F0F5)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? const Color(0xFF6C63FF).withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top: avatar + name/relation ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with online dot
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isOnline
                            ? gradient
                            : [
                                const Color(0xFFE5E7EB),
                                const Color(0xFFD1D5DB)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isOnline
                                  ? gradient[0]
                                  : const Color(0xFF9CA3AF))
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        member.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ade80),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hc ? const Color(0xFF252525) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Name + relation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: hc ? Colors.white : const Color(0xFF1a1a1a),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isOnline
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF9CA3AF))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.relation,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isOnline
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
              height: 1,
              thickness: 1,
              color: hc
                  ? Colors.white12
                  : const Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // ── Bottom: three action buttons ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Video call
              _buildHomeActionBtn(
                icon: Icons.videocam_rounded,
                label: 'فيديو',
                color: const Color(0xFF6C63FF),
                isActive: isOnline,
                hc: hc,
                onTap: () {
                  if (isOnline) {
                    provider.launchZoom(member.zoomLink);
                    provider.addPoints(5);
                  } else {
                    _showFeedbackSnack(
                        '${member.name} غير متاح حالياً للمكالمة');
                  }
                },
              ),
              // Phone call
              _buildHomeActionBtn(
                icon: Icons.phone_rounded,
                label: 'اتصال',
                color: const Color(0xFF4ade80),
                isActive: member.phoneNumber.isNotEmpty,
                hc: hc,
                onTap: () {
                  provider.callPhoneNumber(member.phoneNumber);
                  provider.addPoints(2);
                },
              ),
              // Chat
              _buildHomeActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'رسالة',
                color: const Color(0xFFEA580C),
                isActive: hasApp,
                hc: hc,
                onTap: hasApp
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FamilyResidentChatScreen(
                              otherUserId: member.userId!,
                              otherUserName: member.name,
                              otherUserRole: member.relation,
                              residentId: provider.backendResidentId,
                              accentColor: const Color(0xFF6C63FF),
                            ),
                          ),
                        )
                    : () => _showFeedbackSnack(
                        '${member.name} ليس مستخدماً على تطبيق ونس'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required bool hc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.13)
                  : (hc ? Colors.white10 : const Color(0xFFF3F4F6)),
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive
                  ? color
                  : (hc ? Colors.white38 : const Color(0xFFB0B7C3)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? color
                  : (hc ? Colors.white38 : const Color(0xFFB0B7C3)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF374151),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPointsCard(AppRiverpod provider) {
    int points = provider.currentUser.points;
    double progress = (points / 600.0).clamp(0.0, 1.0);
    int percentage = (progress * 100).toInt();
    bool hc = provider.isHighContrast;
    return Container(
      decoration: BoxDecoration(
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: hc ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
            color: hc ? const Color(0xFF333333) : const Color(0xFFede9fe),
            width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  // جعل قسم النصوص مرناً بالكامل
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        // يضمن أن رقم النقاط الكبير لن يسبب Overflow
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '⭐ $points',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        // يضمن أن الجملة التوضيحية لن تخرج عن حدود الكارت
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'من ٦٠٠ نقطة هذا الشهر',
                          style: TextStyle(
                              fontSize: 16,
                              color: hc ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _starController,
                  builder: (context, child) {
                    final t = _starController.value * 2 * pi;
                    final y = -5 * sin(t * 2);
                    final rot = -8 * sin(t * 2) + 4 * sin(t * 4);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Transform.rotate(
                        angle: rot * pi / 180,
                        child: const Text('🏆', style: TextStyle(fontSize: 36)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                    color:
                        hc ? const Color(0xFF333333) : const Color(0xFFede9fe),
                    borderRadius: BorderRadius.circular(10)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: progress,
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_bgController.value * 4 - 2, 0),
                            end: const Alignment(1, 0),
                            colors: const [
                              Color(0xFFa78bfa),
                              Color(0xFFe9d5ff),
                              Color(0xFFa78bfa)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('٪$percentage — استمر يا بطل! 💪',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7c3aed))),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(AppRiverpod provider, BuildContext context) {
    bool hc = provider.isHighContrast;
    return GestureDetector(
      onTap: () => _showElderlyComplaintSheet(provider, context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: hc ? const Color(0xFF1E1E1E) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color:
                    const Color(0xFFEF4444).withValues(alpha: hc ? 0.2 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
          border: Border.all(
              color: hc ? const Color(0xFF450a0a) : const Color(0xFFFECACA),
              width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCA5A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.room_service_rounded,
                    color: Color(0xFFB91C1C), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب مساعدة / شكوى',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B))),
                    Text('هل تحتاج لشيء؟ نحن هنا لخدمتك.',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFFB91C1C))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showElderlyComplaintSheet(AppRiverpod provider, BuildContext context) {
    String selectedType = 'جودة الطعام';
    final TextEditingController descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24),
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
                const Text('أخبرنا بما يزعجك',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    'جودة الطعام',
                    'صيانة الغرفة',
                    'مساعدة في التنظيف',
                    'أحتاج ممرض',
                    'أخرى'
                  ].map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(type,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'اكتب تفاصيل إضافية إن أردت...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.submitComplaint(
                          descController.text.isNotEmpty
                              ? descController.text
                              : 'طلب من المسن بخصوص $selectedType',
                          selectedType,
                          'مسن');
                      Navigator.pop(context);

                      // Show central animation
                      setState(() {
                        _successMessage =
                            'تم استلام طلبك وسيتوجه فريقنا لخدمتك فوراً';
                        _showSuccessAnimation = true;
                      });

                      // Automatically hides based on onLoaded in _buildCentralSuccessAnimation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('إرسال الطلب',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            // Waves at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: CustomPaint(
                painter: TopWavePainter(_bgController.value),
              ),
            ),

            // Waves in the middle
            Positioned(
              top: 300,
              left: 0,
              right: 0,
              height: 100,
              child: CustomPaint(
                painter: LineWavePainter(_bgController.value),
              ),
            ),

            Positioned(
              top: 600,
              left: 0,
              right: 0,
              height: 100,
              child: CustomPaint(
                painter: LineWavePainter(_bgController.value + 0.5),
              ),
            ),

            // Waves at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: CustomPaint(
                painter: WavePainter(_bgController.value),
              ),
            ),

            // Musical Notes
            FloatingNote(
                animationValue: _bgController.value,
                top: 200,
                left: 50,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 400,
                left: 300,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 600,
                left: 100,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 150,
                left: 250,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 700,
                left: 200,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 300,
                left: 150,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 500,
                left: 20,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 800,
                left: 250,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 100,
                left: 180,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 650,
                left: 280,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 250,
                left: 280,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 450,
                left: 120,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 550,
                left: 220,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 350,
                left: 50,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 750,
                left: 150,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 50,
                left: 100,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 70,
                left: 320,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 120,
                left: 40,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 180,
                left: 130,
                emoji: '🎵'),
          ],
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.45);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.45 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 25,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw another wave
    final paint2 = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.55 +
            cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 20,
      );
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);

    // Draw a third wave
    final paint3 = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, size.height * 0.65);

    for (double i = 0; i <= size.width; i++) {
      path3.lineTo(
        i,
        size.height * 0.65 +
            sin((i / size.width * 3 * pi) + (animationValue * 2 * pi)) * 12,
      );
    }

    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();

    canvas.drawPath(path3, paint3);

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

class FloatingNote extends StatelessWidget {
  final double animationValue;
  final double top;
  final double left;
  final String emoji;

  const FloatingNote({
    super.key,
    required this.animationValue,
    required this.top,
    required this.left,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top + sin(animationValue * 2 * pi) * 20,
      left: left + cos(animationValue * 2 * pi) * 20,
      child: Opacity(
        opacity: 0.25,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

class TopWavePainter extends CustomPainter {
  final double animationValue;
  TopWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 15,
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Draw another wave
    final paint2 = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.4);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.4 +
            cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 12,
      );
    }

    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant TopWavePainter oldDelegate) => true;
}

class LineWavePainter extends CustomPainter {
  final double animationValue;
  LineWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 20,
      );
    }

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.6 +
            cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 15,
      );
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant LineWavePainter oldDelegate) => true;
}
