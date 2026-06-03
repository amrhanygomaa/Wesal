import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class WanasSplashScreen extends StatefulWidget {
  const WanasSplashScreen({super.key, this.status = ''});

  final String status;

  @override
  State<WanasSplashScreen> createState() => _WanasSplashScreenState();
}

class _WanasSplashScreenState extends State<WanasSplashScreen>
    with TickerProviderStateMixin {
  static const String _splashLogoAsset = 'assets/icons/FIRST.png';

  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _sloganOpacity;
  late Animation<double> _glowPulse;
  bool _useLogoAsset = false;

  Future<void> _checkLogoAsset() async {
    try {
      await rootBundle.load(_splashLogoAsset);
      if (mounted) {
        setState(() {
          _useLogoAsset = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _useLogoAsset = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLogoAsset();

    // 1. متحكم أنيميشن ظهور العناصر (ظهور تدريجي وتكبير)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 2. متحكم أنيميشن نبض الخلفية الذهبية الفخمة
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _sloganOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // تشغيل الأنيميشن عند فتح الشاشة
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. الخلفية الفخمة المتدرجة (Cream/Beige Gradient) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF7F2), // درجة كريمي فاتحة ونقية
                  Color(0xFFF3EFE9), // درجة كريمي دافئة
                  Color(0xFFE9E4DC), // درجة أغمق قليلاً للعمق البصري
                ],
              ),
            ),
            child: Image.asset(
              'assets/icons/wanas_splash_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // إذا لم تكن الصورة المخصصة متوفرة بعد كملف، يتم عرض الحلقات والوهج الذهبي الحيوي برمجياً
                return AnimatedBuilder(
                  animation: _glowPulse,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // الوهج العلوي الأيمن
                        Positioned(
                          top: -120 * _glowPulse.value,
                          right: -100 * _glowPulse.value,
                          child: _buildGlowRing(
                            width: 320 * _glowPulse.value,
                            height: 320 * _glowPulse.value,
                            glowColor:
                                const Color(0xFFE8DFCD).withValues(alpha: 0.45),
                            borderColor:
                                const Color(0xFFDFD4BE).withValues(alpha: 0.2),
                          ),
                        ),
                        // الوهج السفلي الأيسر الممتد
                        Positioned(
                          bottom: -150 * _glowPulse.value,
                          left: -120 * _glowPulse.value,
                          child: _buildGlowRing(
                            width: 420 * _glowPulse.value,
                            height: 420 * _glowPulse.value,
                            glowColor:
                                const Color(0xFFE5DBC5).withValues(alpha: 0.4),
                            borderColor:
                                const Color(0xFFDBD0B4).withValues(alpha: 0.18),
                          ),
                        ),
                        // هالة وهج مركزية ناعمة خلف اللوجو مباشرة لزيادة الفخامة
                        Center(
                          child: Container(
                            width: 250 * _glowPulse.value,
                            height: 250 * _glowPulse.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFEFE9DC)
                                      .withValues(alpha: 0.55),
                                  const Color(0xFFFAF7F2)
                                      .withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── 3. محتوى الشاشة الأساسي (المحاذاة والترتيب) ──
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // مسافة علوية متزنة

                  // القسم الأوسط: الشعار + الاسم + الوصف العربي
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أ) الشعار الفخم (الأصل التعبيري للوجو أو الرسم التلقائي)
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: _useLogoAsset
                                  ? Image.asset(
                                      _splashLogoAsset,
                                      width: size.width *
                                          2.5, // تكبير الشعار أكثر وأكثر لتكبير الاسم والرمز للدرجة القصوى المطلوبة
                                      fit: BoxFit.contain,
                                    )
                                  : _buildLogoWidget(),
                            ),
                          );
                        },
                      ),

                      // ب) اسم التطبيق "وَنَسٌ" بالخط العربي المدمج (يظهر فقط في حال تفعيل الرسم التلقائي لمنع التكرار البصري)
                      if (!_useLogoAsset) ...[
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _textOpacity,
                          child: const Text(
                            'وَنَسْ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color:
                                  Color(0xFF8F7C56), // لون ذهبي برونزي فخم جداً
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: Color(0x1F8F7C56),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 0),

                      // ج) العبارة التعبيرية الجديدة "ونس… حيث يطمئن القلب" (مرفوعة للأعلى لتنسجم مع الشعار)
                      Transform.translate(
                        offset: const Offset(0,
                            -25), // تم إنزال النص للأسفل بمقدار 75 بكسل إضافي بناءً على طلب المستخدم ليناسب الشعار الجديد
                        child: FadeTransition(
                          opacity: _sloganOpacity,
                          child: Column(
                            // تم إزالة const لدعم تأثيرات التوهج والألوان البرمجية المدمجة
                            children: [
                              Text(
                                'وَنَسٌ… حَيْثُ يَطْمَئِنُّ القَلْب',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize:
                                      23, // تكبير حجم الخط لمزيد من الفخامة والوضوح
                                  fontWeight: FontWeight.w800,
                                  color: const Color(
                                      0xFF9B7E4B), // لون ذهبي ملكي دافئ وعميق يتناسق بدقة مع اللوجو الذهبي الجديد
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFF5D7A0).withValues(
                                          alpha:
                                              0.35), // توهج خلفي ذهبي ناعم بلون الشعار الجديد لزيادة الفخامة والعمق
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // القسم السفلي: مؤشر التحميل الأنيق + الحقوق
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // لودر دائري ذهبي ناعم متناسق تماماً مع التصميم
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFB09D76), // درجة ذهبية للمؤشر
                          ),
                          backgroundColor:
                              const Color(0xFF8F7C56).withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // نص حالة التحميل
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: widget.status.isNotEmpty
                            ? Text(
                                widget.status,
                                key: ValueKey(widget.status),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9B7E4B),
                                  letterSpacing: 0.3,
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                      const SizedBox(height: 28),

                      // تذييل الصفحة الأنيق: Wanas 2026
                      const Text(
                        'Wanas 2026',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16, // تكبير حجم الخط ليكون واضحاً
                          fontWeight: FontWeight.w700, // خط سميك وجريء
                          color: Color(
                              0xFF8F7C56), // لون ذهبي برونزي كامل بدون شفافية لزيادة الوضوح
                          letterSpacing: 2.0, // تباعد حروف فخم
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء هالة الوهج الدائرية المحاطة بإطار ناعم ومموّه
  Widget _buildGlowRing({
    required double width,
    required double height,
    required Color glowColor,
    required Color borderColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        gradient: RadialGradient(
          colors: [
            glowColor,
            glowColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }

  // بناء الشعار مع ميزة التحقق من توفر الملف أو الرسم التلقائي
  Widget _buildLogoWidget() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F7C56).withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        _splashLogoAsset,
        width: 85,
        height: 85,
        // إذا لم يكن اللوجو المرفوع متوفراً بعد كملف، فسيتم رسم الشعار الذهبي الفاخر تلقائياً بالنظام الفيكتور المدمج
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: const Size(80, 50),
            painter: WanasInfinityLogoPainter(),
          );
        },
      ),
    );
  }
}

// ── رسام مخصص لرسم شعار اللانهاية الذهبي الفاخر المدمج (High-Fidelity Wanas Logo Painter) ──
class WanasInfinityLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // التدرج اللوني الذهبي المعدني الرائع المتطابق مع تدرج الشعار
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8F7C56), // برونزي غامق
          Color(0xFFC7B38C), // ذهبي ناصع دافئ
          Color(0xFFAD9970), // ذهبي معتدل
          Color(0xFF8F7C56), // برونزي غامق للنهاية
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double w = size.width;
    double h = size.height;

    // رسم مسار اللانهاية (Infinity) بانحناءات بيزير التكعيبية الأنيقة والمنسابة
    path.moveTo(w * 0.5, h * 0.5);

    // الحلقة اليسرى للشعار
    path.cubicTo(
      w * 0.32,
      h * 0.15,
      w * 0.05,
      h * 0.15,
      w * 0.08,
      h * 0.5,
    );
    path.cubicTo(
      w * 0.1,
      h * 0.85,
      w * 0.32,
      h * 0.85,
      w * 0.5,
      h * 0.5,
    );

    // الحلقة اليمنى للشعار (تقاطع انسيابي)
    path.cubicTo(
      w * 0.68,
      h * 0.15,
      w * 0.95,
      h * 0.15,
      w * 0.92,
      h * 0.5,
    );
    path.cubicTo(
      w * 0.9,
      h * 0.85,
      w * 0.68,
      h * 0.85,
      w * 0.5,
      h * 0.5,
    );

    canvas.drawPath(path, paint);

    // رسم هالة لمعان ذهبية خفيفة في منتصف التقاطع لزيادة اللمسة الاحترافية
    final glowPaint = Paint()
      ..color = const Color(0xFFFAF4E7).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), 3.0, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
