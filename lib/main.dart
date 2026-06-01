import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية
import 'package:flutter/services.dart'; // مكتبة التحكم في خصائص النظام
import 'package:flutter_localizations/flutter_localizations.dart'; // دعم اللغة العربية
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import 'nav_wrapper.dart'; // غلاف التنقل
import 'screens/auth/login_screen.dart'; // شاشة تسجيل الدخول
import 'screens/nurse/nurse_dashboard_screen.dart'; // لوحة تحكم الممرض
import 'screens/volunteer/volunteer_dashboard_screen.dart'; // لوحة تحكم المتطوع
import 'screens/family/family_dashboard_screen.dart'; // لوحة تحكم الأسرة
import 'screens/specialist/specialist_dashboard_screen.dart'; // لوحة تحكم الأخصائي
import 'screens/admin/admin_dashboard_screen.dart'; // لوحة تحكم الإدارة
import 'screens/onboarding/onboarding_screen.dart'; // شاشة البداية
import 'screens/onboarding/splash_screen.dart'; // شاشة التحميل والترحيب الفخمة (سبلاش)
import 'providers/app_riverpod.dart'; // مزود الحالة
import 'services/notification_service.dart'; // خدمة التنبيهات

/* 
 * الدالة الرئيسية لتشغيل التطبيق:
 * 1. تهيئة بيئة النظام لضمان عمل الأدوات بشكل صحيح.
 * 2. تثبيت اتجاه الشاشة على الوضع الطولي (Portrait) فقط.
 * 3. تفعيل ProviderScope لربط إدارة الحالة بالتطبيق.
 */
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // تهيئة النظام

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[Flutter Error] ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };

  SystemChrome.setPreferredOrientations([
    // تثبيت وضع الشاشة
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    // تشغيل التطبيق
    const ProviderScope(
      // تفعيل إدارة الحالة
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  // المكون الرئيسي
  const MyApp({super.key}); // مشيد الفئة

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // حد أدنى 2.5 ثانية لإكمال أنيميشن الـ splash، ثم يُسيطر isInitialized على الانتقال
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // بناء واجهة المستخدم
    final provider = ref.watch(appRiverpod); // مراقبة الحالة

    // تهيئة خدمة التنبيهات وجدولة المواعيد
    final notifService = ref.read(notificationServiceProvider);
    notifService.initialize(ref).then((_) {
      provider.scheduleMedicationReminders(notifService);
    });

    Widget getHomeWidget() {
      // شاشة السبلاش الفخمة تظهر لمدة ٣ ثوانٍ أو حتى يكتمل تحميل البيانات في الذاكرة
      if (_showSplash || !provider.isInitialized) {
        return WanasSplashScreen(status: provider.splashStatus);
      }

      // تحديد الشاشة الحالية بناءً على حالة المستخدم
      if (!provider.hasSeenOnboarding) {
        return const OnboardingScreen(); // فحص شاشة البداية
      }
      if (!provider.isAuthenticated) {
        return const LoginScreen(); // فحص تسجيل الدخول
      }

      switch (provider.currentRole) {
        // فحص دور المستخدم وتوجيهه لشاشته
        case 'ممرض':
          return const NurseDashboardScreen();
        case 'متطوع':
          return const VolunteerDashboardScreen();
        case 'مسن':
          return const NavWrapper();
        case 'أخصائي اجتماعي':
          return const SocialSpecialistDashboardScreen();
        case 'أسرة':
          return const FamilyDashboardScreen();
        case 'إدارة':
          return const AdminDashboardScreen();
        default:
          return const NavWrapper();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ونس',
      // ── Arabic RTL Configuration ──────────────────────────────
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ────────────────────────────────────────────────────────────
      themeMode: (provider.isDarkMode || provider.isHighContrast)
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // إجبار اتجاه اليمين لليسار
          child: Stack(
            children: [
              MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(provider.fontScaleFactor)),
                child: child!,
              ),
              if (provider.isRefreshingSession) _buildRefreshOverlay(),
            ],
          ),
        );
      },
      theme: ThemeData(
        fontFamily: 'Cairo',
        useMaterial3: true,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1e293b),
          brightness: Brightness.light,
          surface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        // ضبط اتجاه النص في الثيم
        typography: Typography.material2021(platform: TargetPlatform.android),
      ),
      home: getHomeWidget(),
    );
  }

  Widget _buildRefreshOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text('جاري تحديث الجلسة...',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text('برجاء الانتظار لحظة واحدة',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
