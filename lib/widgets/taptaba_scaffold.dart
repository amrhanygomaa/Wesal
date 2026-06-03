import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_riverpod.dart';
import 'taptaba_drawer.dart'; // استيراد القائمة الجانبية
import 'taptaba_bell.dart'; // استيراد أيقونة الإشعارات

class TaptabaScaffold extends ConsumerStatefulWidget {
  // فئة الهيكل الموحد للتطبيق (Scaffold)
  final Widget body; // محتوى الشاشة الأساسي
  final String title; // عنوان الشاشة
  final Color appBarColor; // لون شريط العنوان
  final Color? titleColor; // لون نص العنوان
  final List<Widget>? actions; // أيقونات جانبية في شريط العنوان
  final Widget? bottomNavigationBar; // شريط التنقل السفلي
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final String? overrideRole; // تحديد دور المستخدم لتخصيص القائمة
  final bool extendBody; // هل يمتد المحتوى خلف شريط التنقل السفلي؟
  final bool extendBodyBehindAppBar; // تمديد المحتوى خلف شريط العنوان
  final bool transparentAppBar; // جعل شريط العنوان شفافاً
  final bool hideAppBar; // إخفاء شريط العنوان بالكامل
  final bool useNestedScrollView; // استخدام التمرير المتداخل (للهيدر المتحرك)
  final bool hideAppBarOnScroll; // إخفاء شريط العنوان عند التمرير لأسفل
  final double? appBarHeight; // ارتفاع مخصص لشريط العنوان
  final Widget? sliverHeader; // محتوى إضافي يتحرك مع شريط العنوان (كالـ Hero)

  const TaptabaScaffold({
    // مشيد الفئة مع البارامترات المطلوبة والاختيارية
    super.key,
    required this.body,
    this.title = 'ونس',
    this.appBarColor = Colors.transparent,
    this.titleColor,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.overrideRole,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.transparentAppBar = false,
    this.hideAppBar = false,
    this.useNestedScrollView = true,
    this.hideAppBarOnScroll = true,
    this.appBarHeight,
    this.sliverHeader,
  });

  @override
  ConsumerState<TaptabaScaffold> createState() =>
      _TaptabaScaffoldState(); // إنشاء حالة الهيكل
}

class _TaptabaScaffoldState extends ConsumerState<TaptabaScaffold>
    with SingleTickerProviderStateMixin {
  // حالة الهيكل مع دعم متحكم الأنيميشن
  late AnimationController _drawerController; // متحكم أنيميشن القائمة الجانبية
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // مفتاح الوصول للهيكل

  @override
  void initState() {
    // دالة التهيئة الأولية
    super.initState();
    _drawerController = AnimationController(
      // إعداد متحكم الأنيميشن
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    // تنظيف الموارد عند إغلاق الشاشة
    _drawerController.dispose();
    super.dispose();
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      // إذا hideAppBarOnScroll: يختفي عند النزول ويظهر عند الصعود
      floating: widget.hideAppBarOnScroll,
      snap: widget.hideAppBarOnScroll,
      pinned: !widget.hideAppBarOnScroll,
      toolbarHeight: widget.appBarHeight ??
          56.0, // العودة للارتفاع الافتراضي (56 بكسل) دون تكبيره
      backgroundColor:
          widget.transparentAppBar ? Colors.transparent : Colors.white,
      elevation: 0,
      centerTitle: true,
      forceElevated: innerBoxIsScrolled,
      iconTheme: const IconThemeData(color: Color(0xFF64748b)),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748b)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: _buildTitle(),
      actions: _buildActions(),
    );
  }

  Widget _buildFixedAppBar() {
    return AppBar(
      backgroundColor:
          widget.transparentAppBar ? Colors.transparent : Colors.white,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: widget.appBarHeight ??
          56.0, // العودة للارتفاع الافتراضي (56 بكسل) دون تكبيره
      iconTheme: const IconThemeData(color: Color(0xFF64748b)),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748b)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: _buildTitle(),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    final isWanasTitle =
        widget.title.trim() == 'ونس' || widget.title.trim() == 'طبطبة';

    if (isWanasTitle) {
      final isDark = Theme.of(context).brightness == Brightness.dark ||
          ref.watch(appRiverpod).isDarkMode;

      // تحديد اللون النشط للصفحة لصبغ الشعار به ديناميكياً ليتناسق تماماً مع نمط وألوان الصفحة
      final activeColor = widget.titleColor ??
          (isDark ? const Color(0xFFFAF7F2) : const Color(0xFF6C63FF));

      return Transform.scale(
        scale:
            1.45, // تكبير الشعار بصرياً بنسبة 145% ليكون ضخماً وواضحاً جداً دون تكبير مقاس شريط التنقل نفسه
        child: Image.asset(
          'assets/icons/wanas_logo_nav.png',
          height:
              42, // الحجم الفعلي المحجوز في التخطيط ليتناسب مع الـ 56 بكسل الافتراضية
          fit: BoxFit.contain,
          // صبغ الشعار ديناميكياً بلون النمط النشط للصفحة الحالية
          color: activeColor,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            // نص احتياطي لتجنب أي انهيار في حال تعذر تحميل الصورة
            return Text(
              'ونس',
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                fontFamily: 'Cairo',
                letterSpacing: 1.2,
              ),
            );
          },
        ),
      );
    }

    // للشاشات الفرعية الأخرى، نعرض اسم الشاشة كنص عادي وأنيق
    return Text(
      widget.title,
      style: TextStyle(
        color: widget.titleColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1E293B)),
        fontWeight: FontWeight.w900,
        fontSize: 22,
        fontFamily: 'Cairo',
        letterSpacing: 1.0,
      ),
    );
  }

  List<Widget> _buildActions() {
    return widget.actions ??
        [
          if ((widget.overrideRole ?? ref.watch(appRiverpod).currentRole) ==
              'مسن')
            IconButton(
              icon: const Text('🏆', style: TextStyle(fontSize: 22)),
              onPressed: () {
                ref.read(appRiverpod).setElderlyTabIndex(4);
              },
            ),
          const TaptabaBell(),
          const SizedBox(width: 8),
        ];
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء الواجهة
    return Scaffold(
      key: _scaffoldKey,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: TaptabaDrawer(
          overrideRole: widget.overrideRole), // القائمة الجانبية الموحدة
      body: widget.hideAppBar
          ? widget.body
          : (widget.useNestedScrollView
              ? NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      _buildSliverAppBar(innerBoxIsScrolled),
                      if (widget.sliverHeader != null)
                        SliverToBoxAdapter(child: widget.sliverHeader!),
                    ];
                  },
                  body: widget.body,
                )
              : Column(
                  children: [
                    _buildFixedAppBar(),
                    Expanded(child: widget.body),
                  ],
                )),
      bottomNavigationBar:
          widget.bottomNavigationBar, // شريط التنقل السفلي إن وجد
      floatingActionButton: widget.floatingActionButton, // الزر العائم إن وجد
      floatingActionButtonLocation:
          widget.floatingActionButtonLocation, // موقع الزر العائم
    );
  }
}
