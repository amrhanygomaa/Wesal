import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import '../../providers/app_riverpod.dart'; // استيراد مزود الحالة الرئيسي
import 'views/admin_home_view.dart'; // واجهة الإحصائيات العامة للمدير
import 'views/residents_management_view.dart'; // واجهة إدارة المقيمين
import 'views/staff_management_view.dart'; // واجهة إدارة طاقم العمل
import 'views/visit_approval_view.dart'; // واجهة مراجعة طلبات الزيارة
import '../specialist/views/complaints_view.dart'; // واجهة الشكاوى والاقتراحات للمدير
import 'views/admin_reports_view.dart'; // واجهة التقارير الإدارية والمالية
import 'views/admin_volunteer_view.dart'; // واجهة إدارة التطوع المستحدثة
import '../common/profile_screen.dart'; // شاشة الملف الشخصي العامة
// القائمة الجانبية الموحدة
import '../../widgets/taptaba_scaffold.dart'; // الهيكل الموحد للتطبيق
// مكتبة الأنيميشن

class AdminDashboardScreen extends ConsumerStatefulWidget {
  // شاشة لوحة تحكم المدير العام
  const AdminDashboardScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState(); // إنشاء حالة المكون
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن
  late AnimationController _fadeController; // متحكم أنيميشن التلاشي
  late List<Animation<double>> _fadeAnimations; // قائمة حركات التلاشي المتسلسلة
  late AnimationController _floatController; // متحكم أنيميشن الطفو للأيقونات
  late AnimationController _shimmerController; // متحكم أنيميشن اللمعان
  late AnimationController _popController; // متحكم أنيميشن الظهور المفاجئ

  @override
  void initState() {
    // دالة التهيئة الأولية عند تشغيل الشاشة
    super.initState();
    _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000)); // إعداد متحكم التلاشي
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true); // إعداد متحكم الطفو المستمر
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _popController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();

    _fadeAnimations = List.generate(15, (index) {
      // إنشاء تسلسل حركات ظهور للعناصر (Staggered Animation)
      final begin = min(index * 0.05, 0.9);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(begin, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _fadeController.forward(); // بدء تشغيل أنيميشن الظهور
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(appRiverpod).currentAdminTabIndex == 2) {
        unawaited(ref.read(appRiverpod).syncBackendData());
      }
    });
  }

  @override
  void dispose() {
    // تنظيف متحكمات الأنيميشن عند إغلاق الشاشة
    _fadeController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    // دالة معالجة تغيير التبويب
    ref.read(appRiverpod).setAdminTabIndex(index); // تحديث التبويب في ريفربود
    if (index == 2) {
      unawaited(ref.read(appRiverpod).syncBackendData());
    }
    _fadeController.reset(); // إعادة تعيين أنيميشن التلاشي
    _fadeController.forward(); // إعادة تشغيل الأنيميشن للتبويب الجديد
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء واجهة المدير الرئيسية
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق

    ref.listen<AppRiverpod>(appRiverpod, (previous, next) {
      if (previous?.currentAdminTabIndex != next.currentAdminTabIndex) {
        _fadeController.reset();
        _fadeController.forward();
      }
    });

    return TaptabaScaffold(
      // استخدام الهيكل الموحد "ونس"
      title: 'ونس', // اسم التطبيق
      titleColor: const Color(0xFF1e293b), // لون العنوان (كحلي غامق رسمي)
      overrideRole: 'مدير', // تحديد دور المدير للألوان الداكنة والاحترافية
      bottomNavigationBar:
          _buildDirectorNav(provider), // بناء شريط التنقل السفلي المخصص للمدير
      body: Stack(
        children: [
          // خلفية حيوية بسيطة (Floating Blobs)
          Positioned.fill(child: _buildLivelyBackground()),
          SingleChildScrollView(
            child: Column(
              children: [
                if (provider.currentAdminTabIndex == 0)
                  _buildDirectorHero(provider),
                _getCurrentView(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivelyBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Stack(
          children: [
            // 1. بقعة زرقاء علوية يمين
            Positioned(
              top: 50 + (50 * sin(_floatController.value * pi)),
              right: -100 + (30 * cos(_floatController.value * pi)),
              child: _buildBlob(
                  400, const Color(0xFF0ea5e9).withValues(alpha: 0.15)),
            ),
            // 2. بقعة بنفسجية سفلية يسار
            Positioned(
              bottom: 100 + (60 * cos(_floatController.value * pi)),
              left: -120 + (40 * sin(_floatController.value * pi)),
              child: _buildBlob(
                  500, const Color(0xFF6366f1).withValues(alpha: 0.12)),
            ),
            // 3. بقعة وردية في المنتصف تتحرك بشكل مختلف
            Positioned(
              top: 300 + (40 * sin(_floatController.value * 2 * pi)),
              left: 100 + (30 * cos(_floatController.value * 2 * pi)),
              child: _buildBlob(
                  300, const Color(0xFFf43f5e).withValues(alpha: 0.08)),
            ),
            // 4. بقعة سماوية هادئة
            Positioned(
              bottom: 400 + (50 * sin(_floatController.value * pi)),
              right: 20 + (20 * cos(_floatController.value * pi)),
              child: _buildBlob(
                  350, const Color(0xFF22d3ee).withValues(alpha: 0.1)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.01),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _getCurrentView(AppRiverpod provider) {
    // إرجاع الواجهة المطلوبة بناءً على التبويب المختار
    switch (provider.currentAdminTabIndex) {
      case 0:
        return AdminHomeView(
            fadeAnimations: _fadeAnimations, floatController: _floatController);
      case 1:
        return ResidentsManagementView(fadeAnimations: _fadeAnimations);
      case 2:
        return VisitApprovalView(fadeAnimations: _fadeAnimations);
      case 3:
        return SpecialistComplaintsView(
          fadeAnimations: _fadeAnimations,
          floatController: _floatController,
          shimmerController: _shimmerController,
          popController: _popController,
          onNavigate: _onTabChanged,
          isAdmin: true,
        );
      case 4:
        return StaffManagementView(fadeAnimations: _fadeAnimations);
      case 5:
        return AdminReportsView(fadeAnimations: _fadeAnimations);
      case 6:
        return AdminVolunteerView(fadeAnimations: _fadeAnimations);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDirectorHero(AppRiverpod provider) {
    // بناء منطقة الـ Hero الخاصة بالمدير مع تأثير زجاجي وأنيمشن قوي
    final adminName = provider.currentAccount?.name.trim().isNotEmpty == true
        ? provider.currentAccount!.name.trim()
        : 'المدير';
    final facilityName =
        provider.currentAccount?.facilityName?.trim().isNotEmpty == true
            ? provider.currentAccount!.facilityName!.trim()
            : provider.facilityName.trim().isEmpty
                ? 'المنشأة'
                : provider.facilityName.trim();

    return ClipRect(
      child: BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 10, sigmaY: 10), // تأثير التغبيش الزجاجي
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0f172a)
                .withValues(alpha: 0.85), // لون داكن شبه شفاف
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
          ),
          child: Stack(
            children: [
              // 1. شكل متحرك يسبح في الخلفية (الجهة العلوية)
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Positioned(
                    top: -100 + (20 * sin(_floatController.value * 2 * pi)),
                    left: -100 + (30 * cos(_floatController.value * 2 * pi)),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF0ea5e9).withValues(alpha: 0.2),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // 2. شكل متحرك آخر يسبح في الجهة السفلية بتوقيت مختلف
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Positioned(
                    bottom: -80 + (25 * cos(_floatController.value * 2 * pi)),
                    right: -50 + (40 * sin(_floatController.value * 2 * pi)),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF38bdf8).withValues(alpha: 0.18),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // 3. نبض ضوئي خفيف في المنتصف
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.05 + (0.05 * sin(_floatController.value * pi)),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // المحتوى الأساسي للـ Hero
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ProfileScreen(overrideRole: 'إدارة')),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('أهلاً يا $adminName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2)),
                            const SizedBox(height: 6),
                            Text('مدير الدار · $facilityName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAnimatedBadge() {
    // بناء شارة المدير مع أنيميشن الطفو
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 3 * _floatController.value), // حركة رأسية خفيفة
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Color(0xFF0ea5e9),
                shape: BoxShape.circle), // شارة زرقاء دائرية
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 18), // أيقونة درع الحماية
          ),
        );
      },
    );
  }

  Widget _buildDirectorNav(AppRiverpod provider) {
    // بناء شريط التنقل السفلي المخصص للمدير
    final activeIndex = provider.currentAdminTabIndex;
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ], // ظل خفيف للأعلى
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
              child: _buildNavItem(
                  0, Icons.analytics_outlined, 'نظرة عامة', activeIndex)),
          Expanded(
              child: _buildNavItem(
                  2, 'assets/icons/calendar.png', 'الزيارات', activeIndex)),
          Expanded(
              child: _buildNavItem(
                  3, Icons.error_outline_rounded, 'الشكاوى', activeIndex)),
          Expanded(
              child: _buildNavItem(
                  6, Icons.volunteer_activism_outlined, 'التطوع', activeIndex)),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, dynamic icon, String label, int activeIndex) {
    // قالب عنصر التنقل في الشريط السفلي
    final isAct = activeIndex == index; // هل هذا التبويب هو النشط حالياً؟
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        // حاوية متحركة لتغيير الخلفية بسلاسة
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: isAct
            ? BoxDecoration(
                color: const Color(0xFFf0f9ff),
                borderRadius: BorderRadius.circular(20))
            : null, // خلفية زرقاء فاتحة للمختار
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon is IconData
                ? Icon(icon,
                    color: isAct
                        ? const Color(0xFF0ea5e9)
                        : const Color(0xFF64748b),
                    size: 26)
                : Image.asset(icon as String,
                    color: isAct
                        ? const Color(0xFF0ea5e9)
                        : const Color(0xFF64748b),
                    width: 26,
                    height: 26), // تغيير لون الأيقونة
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color:
                      isAct ? const Color(0xFF0ea5e9) : const Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: isAct ? FontWeight.bold : FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({required this.text, required this.style, super.key});

  @override
  State<MarqueeText> createState() => MarqueeTextState();
}

class MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _scrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: widget.text.length * 200),
            curve: Curves.linear,
          );
          await Future.delayed(const Duration(seconds: 1));
          if (_scrollController.hasClients) {
            await _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );
  }
}
