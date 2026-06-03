import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

class FamilyActivitiesScreen extends ConsumerStatefulWidget {
  const FamilyActivitiesScreen({super.key});

  @override
  ConsumerState<FamilyActivitiesScreen> createState() =>
      _FamilyActivitiesScreenState();
}

class _FamilyActivitiesScreenState extends ConsumerState<FamilyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimations = List.generate(8, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.12, 1.0, curve: Curves.easeOut),
        ),
      );
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildActivityIcon(String emoji) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (emoji) {
      case '📚':
        iconData = Icons.auto_stories_rounded;
        iconColor = const Color(0xFFe11d48); // Rose red
        bgColor = const Color(0xFFfff1f2);
        break;
      case '🧘':
        iconData = Icons.self_improvement_rounded;
        iconColor = const Color(0xFF0d9488); // Teal
        bgColor = const Color(0xFFf0fdfa);
        break;
      case '🧩':
        iconData = Icons.psychology_rounded;
        iconColor = const Color(0xFF8b5cf6); // Purple/Violet
        bgColor = const Color(0xFFf5f3ff);
        break;
      case '🌳':
        iconData = Icons.park_rounded;
        iconColor = const Color(0xFF059669); // Emerald green
        bgColor = const Color(0xFFecfdf5);
        break;
      case '📱':
        iconData = Icons.videocam_rounded;
        iconColor = const Color(0xFF2563eb); // Royal blue
        bgColor = const Color(0xFFeff6ff);
        break;
      case '🩺':
        iconData = Icons.monitor_heart_rounded;
        iconColor = const Color(0xFFdc2626); // Red
        bgColor = const Color(0xFFfef2f2);
        break;
      case '🎨':
        iconData = Icons.palette_rounded;
        iconColor = const Color(0xFFd946ef); // Fuchsia
        bgColor = const Color(0xFFfdf4ff);
        break;
      default:
        iconData = Icons.event_note_rounded;
        iconColor = const Color(0xFFea580c); // Orange
        bgColor = const Color(0xFFfff7ed);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  String _getEmotionalPrompt(Activity act, String residentName) {
    switch (act.emoji) {
      case '📚':
        return 'جلسة هادئة تزيد من صفاء ذهن $residentName. ما رأيك أن تبدأ يومك معه بممارسة القراءة ومناقشة صفحاتها الدافئة؟';
      case '🧘':
        return 'جلسة لتمارين الاسترخاء واليوغا الصباحية لـ $residentName. تواجدك ومشاركتك معه سيمد جسده بالنشاط وقلبه بالفرح الغامر!';
      case '🧩':
        return 'تحدٍ وتسلية في مسابقة الذاكرة والذكاء. شارك $residentName وشكّلا معاً فريقاً رائعاً اليوم!';
      case '🌳':
        return 'النسيم العليل والهدوء بانتظار $residentName. نزهة دافئة معه في الهواء الطلق هي كل ما يتمناه اليوم.';
      case '📱':
        return 'تواصل عائلي دافئ اليوم كفيل بأن يملأ قلب $residentName طمأنينة وسروراً.';
      case '🩺':
        return 'فحص طبي روتيني لـ $residentName. تواجدك بجانبه يمنحه الطمأنينة والقوة، ويجعله يشعر بدعمك الدائم.';
      default:
        return 'نشاط ممتع وصحي ينتظر $residentName اليوم. مشاركتك البسيطة ستصنع بهجة حقيقية وفارقاً كبيراً في يومه.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'المقيم العزيز';

    final todayActivities = provider.activities
        .where((a) => a.dayTag == 'اليوم' || a.dayTag == 'أمس')
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFfafaf9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF334155), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الأنشطة العائلية',
            style: TextStyle(
              color: Color(0xFFea580c),
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            todayActivities.isEmpty
                ? _buildEmptyState(residentName)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: todayActivities.length,
                    itemBuilder: (context, index) {
                      final act = todayActivities[index];
                      final animIndex = min(index, _fadeAnimations.length - 1);
                      return FadeTransition(
                        opacity: _fadeAnimations[animIndex],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: Interval(animIndex * 0.1, 1.0,
                                  curve: Curves.easeOutBack),
                            ),
                          ),
                          child: _buildActivityCard(
                              context, act, provider, residentName),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child:
                _buildOrb(260, const Color(0xFFffedd5).withValues(alpha: 0.5)),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child:
                _buildOrb(220, const Color(0xFFffe4e6).withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEmptyState(String residentName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFeab308), size: 48),
            const SizedBox(height: 16),
            Text(
              'لا توجد أنشطة مجدولة لـ $residentName حالياً',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748b),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'سيقوم الأخصائي الاجتماعي بنشر الأنشطة فور تجهيزها. ابقَ قريباً!',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Color(0xFF94a3b8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity act,
      AppRiverpod provider, String residentName) {
    final isJoined = provider.isFamilyParticipating(act.id);
    final note = provider.getFamilyActivityNote(act.id);

    if (!_controllers.containsKey(act.id)) {
      _controllers[act.id] = TextEditingController(text: note);
    }
    final controller = _controllers[act.id]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isJoined ? const Color(0xFFa7f3d0) : const Color(0xFFf1f5f9),
          width: isJoined ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isJoined
                ? const Color(0xFF059669).withValues(alpha: 0.05)
                : const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityIcon(act.emoji),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              act.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0f172a),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isJoined
                                  ? const Color(0xFFd1fae5)
                                  : const Color(0xFFf1f5f9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isJoined ? 'تم تسجيل حضورك' : 'غير مسجل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isJoined
                                    ? const Color(0xFF065f46)
                                    : const Color(0xFF64748b),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Color(0xFF64748b),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            act.time,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748b),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Color(0xFFef4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            act.location,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                      if (act.supervisor != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: Color(0xFF94a3b8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'المشرف الأخصائي: ${act.supervisor}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: Color(0xFF94a3b8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Emotional Touch Callout Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isJoined
                    ? [const Color(0xFFf0fdf4), const Color(0xFFecfdf5)]
                    : [const Color(0xFFfff7ed), const Color(0xFFfffbeb)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isJoined
                    ? const Color(0xFFd1fae5)
                    : const Color(0xFFffedd5),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isJoined
                      ? Icons.favorite_rounded
                      : Icons.lightbulb_outline_rounded,
                  color: isJoined
                      ? const Color(0xFF059669)
                      : const Color(0xFFea580c),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isJoined
                        ? 'مشاركتك الرائعة ستجعل $residentName يشعر بقربك وحبك العميق. لقد أسعدت قلبه اليوم!'
                        : _getEmotionalPrompt(act, residentName),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isJoined
                          ? const Color(0xFF065f46)
                          : const Color(0xFF9a3412),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Interaction Field for custom notes/gifts
          if (isJoined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إضافة مفاجأة أو ملاحظة خاصة (مثال: سأجلب الشوكولاتة المفضلة)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf8fafc),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFe2e8f0)),
                          ),
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0f172a),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'سأحضر معي هدية بسيطة...',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94a3b8),
                                fontFamily: 'Cairo',
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          provider.updateFamilyActivityNote(
                              act.id, controller.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم حفظ الملاحظة وتوجيهها للمشرف',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Joint Activity Action Button with FittedBox to prevent overflow
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final nowJoined = provider.toggleFamilyActivityAttendance(
                    act,
                    residentName: residentName,
                  );
                  if (nowJoined) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم ربط النشاط بنجاح! تم تسجيل مشاركتك في "${act.name}"',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: isJoined
                      ? const Color(0xFFd1fae5)
                      : const Color(0xFFea580c),
                  foregroundColor:
                      isJoined ? const Color(0xFF065f46) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isJoined
                        ? const BorderSide(color: Color(0xFF34d399), width: 1)
                        : BorderSide.none,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isJoined
                            ? 'مشارك بنجاح (إلغاء)'
                            : 'تأكيد مشاركتي في النشاط',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isJoined
                            ? Icons.check_circle_rounded
                            : Icons.favorite_rounded,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
