import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة ريفربود
import 'dart:ui'; // مكتبة لواجهات المستخدم المتقدمة مثل البلور
import 'package:url_launcher/url_launcher.dart'; // لفتح روابط الخرائط

import '../../providers/app_riverpod.dart'; // استيراد مزود الحالة الخاص بالتطبيق
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_popup_notification.dart';
import 'register_screen.dart'; // استيراد شاشة التسجيل الجديدة

class LoginScreen extends ConsumerStatefulWidget {
  // شاشة تسجيل الدخول كمكون تفاعلي مع ريفربود
  const LoginScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<LoginScreen> createState() =>
      _LoginScreenState(); // إنشاء حالة المكون
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن
  late AnimationController _fadeController; // متحكم أنيميشن الظهور التدريجي
  late List<Animation<double>> _fadeAnimations; // قائمة حركات الظهور للعناصر
  late TextEditingController
      _identifierController; // متحكم حقل المعرف (هاتف أو إيميل)
  late TextEditingController _passwordController; // متحكم حقل كلمة المرور
  bool _isLoggingIn = false;
  bool _showPassword = false;

  @override
  void initState() {
    // دالة تهيئة الحالة عند بدء الشاشة
    super.initState(); // استدعاء دالة التهيئة الأصلية
    _identifierController = TextEditingController(); // تهيئة متحكم المعرف
    _passwordController = TextEditingController(); // تهيئة متحكم كلمة المرور

    _fadeController = AnimationController(
      // إعداد متحكم الظهور التدريجي
      vsync: this, // المزامنة مع الشاشة
      duration: const Duration(seconds: 1), // مدة الظهور ثانية واحدة
    );

    _fadeAnimations = List.generate(
      // توليد حركات الظهور للعناصر بشكل متتابع
      6, // عدد العناصر التي ستتحرك
      (index) => Tween<double>(begin: 0, end: 1).animate(
        // الحركة من اختفاء إلى ظهور
        CurvedAnimation(
          // نوع منحنى الحركة
          parent: _fadeController, // المتحكم الأب
          curve: Interval(index * 0.1, 1.0,
              curve: Curves.easeOut), // توقيت كل عنصر
        ),
      ),
    );
    _fadeController.forward(); // البدء في تنفيذ أنيميشن الظهور
  }

  @override
  void dispose() {
    // دالة تنظيف الموارد عند إغلاق الشاشة
    _fadeController.dispose(); // إغلاق متحكم الظهور
    _identifierController.dispose(); // إغلاق متحكم المعرف
    _passwordController.dispose(); // إغلاق متحكم كلمة المرور
    super.dispose(); // استدعاء دالة التنظيف الأصلية
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء واجهة الشاشة
    return Scaffold(
      // الهيكل الأساسي للصفحة
      body: Stack(
        // تكديس العناصر فوق بعضها (الخلفية ثم المحتوى)
        children: [
          // الخلفية الأنيقة المتسقة مع شاشة البدء - صورة wanas_splash_bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF7F2), // درجة كريمي فاتحة ونقية
                  Color(0xFFF3EFE9), // درجة كريمي دافئة
                  Color(0xFFE9E4DC), // درجة أغمق للعمق البصري
                ],
              ),
            ),
            child: Image.asset(
              'assets/icons/loginback.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          // Blur Effect - تأثير الضبابية للزجاج
          Positioned.fill(
            // تغطية كامل الشاشة
            child: BackdropFilter(
              // فلتر لخلفية العناصر
              filter: ImageFilter.blur(
                  sigmaX: 4,
                  sigmaY: 4), // تقليل شدة الضبابية لتظهر الخلفية بوضوح
              child: Container(
                  color: Colors.white.withValues(
                      alpha:
                          0.05)), // جعل الغطاء أكثر شفافية لتأثير أكثر وضوحاً
            ),
          ),

          // Content - المحتوى الأساسي
          SafeArea(
            // التأكد من عدم تداخل المحتوى مع حواف الهاتف (النوتش)
            child: Center(
              // توسيط المحتوى في الشاشة
              child: SingleChildScrollView(
                // السماح بالتمرير عند صغر الشاشة
                padding: const EdgeInsets.symmetric(
                    horizontal: 24), // حواف جانبية 24
                child: Column(
                  // ترتيب العناصر رأسياً
                  mainAxisAlignment: MainAxisAlignment.center, // توسيط رأسي
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // تمديد العناصر أفقياً
                  children: [
                    FadeTransition(
                      // أنيميشن ظهور الشعار
                      opacity: _fadeAnimations[0], // استخدام أول حركة ظهور
                      child: Column(
                        // عمود للشعار والاسم
                        children: [
                          const SizedBox(
                              height:
                                  15), // مسافة علوية كافية تمنع تداخل الشعار الكبير مع الحافة العلوية للشاشة
                          // شعار تسجيل الدخول المخصص الجديد - تم تكبيره بصرياً لتجاوز الحواف الشفافة وقيود العرض
                          Transform.scale(
                            scale:
                                1.85, // تكبير الشعار والاسم نفسه بصرياً بنسبة 185% للوصول لأقصى حجم بارز وجذاب
                            child: Image.asset(
                              'assets/icons/LOGO_LOGIN.png',
                              height:
                                  165, // ارتفاع مثالي ليتناسق مع الحجم الضخم الجديد
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 56,
                                    color: Color(0xFFD2AF7D),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                              height:
                                  1), // مسافة مريحة وقريبة تمنع الفراغات الكبيرة وتجمع اللوجو مع العبارة بانسجام
                          const Text(
                            'ونس… حيث يطمئن القلب وتدفأ الروح', // العبارة الإنسانية الدافئة والجميلة البديلة
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  18, // زيادة حجم الخط ليظهر عريضاً ومقروءاً للغاية
                              color: Color(0xFF8F7C56), // تدرج لوني مذهب متناسق
                              fontWeight: FontWeight
                                  .w900, // تسميك وتخين الخط للدرجة القصوى لجعله غاية في الوضوح والبروز
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // مسافة قبل الكارت الأساسي

                    // Glassmorphic Card - كارت إدخال البيانات الزجاجي
                    FadeTransition(
                      // أنيميشن ظهور الكارت
                      opacity: _fadeAnimations[1], // ثاني حركة ظهور
                      child: Container(
                        // وعاء محتوى تسجيل الدخول
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                              alpha: 0.7), // أبيض شفاف (تأثير الزجاج)
                          borderRadius:
                              BorderRadius.circular(32), // حواف دائرية كبيرة
                          border: Border.all(
                              color: Colors.white, width: 2), // إطار أبيض ناصع
                          boxShadow: [
                            // ظل عميق للكارت
                            BoxShadow(
                              color: const Color(0xFF312e81)
                                  .withValues(alpha: 0.08), // لون ظل نيلي خفيف
                              blurRadius: 32, // مدى تلاشي الظل
                              offset: const Offset(0, 16), // إزاحة الظل للأسفل
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24), // حواف داخلية للكارت
                        child: Column(
                          // عناصر الكارت الداخلية
                          crossAxisAlignment:
                              CrossAxisAlignment.end, // محاذاة لليمين (عربي)
                          children: [
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(
                                      0xFF5A4B31), // لون دافئ متناسق مع الشعار
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(height: 24), // مسافة فارغة

                            const SizedBox(
                                height:
                                    8), // مسافة بسيطة بدلاً من اختيار الأدوار

                            // Inputs - حقول الإدخال
                            FadeTransition(
                              // أنيميشن ظهور حقل المعرف
                              opacity: _fadeAnimations[3], // رابع حركة ظهور
                              child: _buildInput(
                                // بناء حقل إدخال مخصص
                                controller:
                                    _identifierController, // ربط متحكم المعرف
                                label:
                                    'البريد الإلكتروني أو رقم الهاتف', // نص تلميحي
                                icon: Icons
                                    .person_outline_rounded, // أيقونة الشخص
                              ),
                            ),
                            const SizedBox(height: 16), // مسافة بين الحقول

                            FadeTransition(
                              // أنيميشن ظهور حقل كلمة المرور
                              opacity: _fadeAnimations[
                                  3], // نفس توقيت ظهور الحقل السابق
                              child: _buildInput(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline_rounded,
                                isPassword: !_showPassword,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _showPassword = !_showPassword),
                                  child: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF94a3b8),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    _showForgotPasswordSheet(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    color: Color(0xFF9B7E4B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Login Button - زر تسجيل الدخول
                            FadeTransition(
                              opacity: _fadeAnimations[4],
                              child: Row(
                                children: [
                                  // biometric icon button — يظهر فقط لو مفعّل
                                  _buildBiometricIconButton(),
                                  if (ref.watch(appRiverpod).isBiometricEnabled)
                                    const SizedBox(width: 12),
                                  // زر دخول
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _isLoggingIn ? null : _handleLogin,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFD2AF7D),
                                              Color(0xFFE1BE8C),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFD2AF7D)
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: _isLoggingIn
                                            ? const SizedBox(
                                                height: 22,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                ),
                                              )
                                            : const Text(
                                                'دخول',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimations[5],
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const RegisterScreen()),
                                        ),
                                        child: const Text(
                                          'أنشئ حساباً الآن',
                                          style: TextStyle(
                                            color: Color(
                                                0xFF9B7E4B), // لون ذهبي ملكي دافئ متناسق مع الشعار
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'ليس لديك حساب؟',
                                        style: TextStyle(
                                          color: Color(0xFF64748b),
                                          fontSize: 14,
                                        ),
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
                    // استعلام عن مكان شاغر — خارج الكارت
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _showGuestInquirySheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF10b981)
                                  .withValues(alpha: 0.35),
                              width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded,
                                color: Color(0xFF10b981), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'استعلام عن مكان شاغر بالدار',
                              style: TextStyle(
                                color: Color(0xFF10b981),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final id = _identifierController.text.trim();
    final password = _passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      _showSnack('يرجى إدخال البريد وكلمة المرور', error: true);
      return;
    }

    setState(() => _isLoggingIn = true);
    final provider = ref.read(appRiverpod);
    final success = await provider.login(id, password);

    if (!mounted) return;

    if (success) {
      setState(() => _isLoggingIn = false);
      // _showSnack('تم تسجيل الدخول بنجاح');
    } else {
      final challenge =
          await provider.beginTemporaryPasswordActivation(id, password);
      if (!mounted) return;
      setState(() => _isLoggingIn = false);
      if (challenge != null) {
        _showTemporaryPasswordSheet(challenge);
        return;
      }
      _showSnack(provider.backendSyncError ?? 'تعذر تسجيل الدخول عبر السيرفر',
          error: true);
    }
  }

  void _showTemporaryPasswordSheet(CognitoNewPasswordChallenge challenge) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    var loading = false;
    var showPassword = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'تفعيل حساب الأسرة',
                    style: TextStyle(
                      color: Color(0xFF5A4B31),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'كلمة المرور التي وصلتك مؤقتة. عيّن كلمة مرور جديدة لإكمال التفعيل والدخول.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.6,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 18),
                _buildInput(
                  controller: newPassCtrl,
                  label: 'كلمة المرور الجديدة',
                  icon: Icons.lock_reset_rounded,
                  isPassword: !showPassword,
                  suffixIcon: GestureDetector(
                    onTap: () => setSheet(() => showPassword = !showPassword),
                    child: Icon(
                      showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInput(
                  controller: confirmPassCtrl,
                  label: 'تأكيد كلمة المرور الجديدة',
                  icon: Icons.lock_outline_rounded,
                  isPassword: !showPassword,
                  suffixIcon: _passwordVisibilityButton(
                    visible: showPassword,
                    onTap: () => setSheet(() => showPassword = !showPassword),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: loading
                      ? null
                      : () async {
                          final newPass = newPassCtrl.text;
                          final confirmPass = confirmPassCtrl.text;
                          final validation =
                              _validateActivationPassword(newPass, confirmPass);
                          if (validation != null) {
                            _showSnack(validation, error: true);
                            return;
                          }

                          setSheet(() => loading = true);
                          final provider = ref.read(appRiverpod);
                          final ok = await provider
                              .completeTemporaryPasswordActivation(
                            challenge,
                            newPass,
                          );

                          if (!ctx.mounted) return;
                          setSheet(() => loading = false);
                          if (ok) {
                            Navigator.pop(ctx);
                            if (mounted) {
                              _showSnack('تم تفعيل الحساب وتسجيل الدخول بنجاح');
                            }
                          } else if (mounted) {
                            _showSnack(
                              provider.backendSyncError ?? 'تعذر تفعيل الحساب',
                              error: true,
                            );
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFD2AF7D),
                        Color(0xFFE1BE8C),
                      ]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFD2AF7D).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : const Text(
                            'تفعيل الحساب',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      newPassCtrl.dispose();
      confirmPassCtrl.dispose();
    });
  }

  String? _validateActivationPassword(String password, String confirm) {
    if (password.trim().isEmpty) return 'يرجى إدخال كلمة المرور الجديدة';
    if (password.length < 8) return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على رقم';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على رمز خاص';
    }
    if (password != confirm) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    showAppPopupNotification(
      context,
      message: message,
      type: error
          ? AppPopupNotificationType.error
          : AppPopupNotificationType.success,
    );
  }

  Widget _buildBiometricIconButton() {
    final provider = ref.watch(appRiverpod);
    if (!provider.isBiometricEnabled) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _isLoggingIn ? null : _handleBiometricLogin,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFD2AF7D).withValues(alpha: 0.6),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFD2AF7D).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.fingerprint_rounded,
            color: Color(0xFF9B7E4B), size: 28),
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoggingIn = true);

    final authenticated = await BiometricService.instance
        .authenticate(reason: 'أكّد هويتك لتسجيل الدخول');
    if (!mounted) return;

    if (!authenticated) {
      setState(() => _isLoggingIn = false);
      _showSnack('فشل التحقق البيومتري', error: true);
      return;
    }

    final provider = ref.read(appRiverpod);
    final success = await provider.loginWithBiometric();
    setState(() => _isLoggingIn = false);

    if (!mounted) return;
    if (!success) {
      _showSnack('يرجى إعادة إعداد البصمة من إعدادات الحساب', error: true);
    }
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF94a3b8), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(icon, color: const Color(0xFF94a3b8), size: 20),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: suffixIcon,
                )
              : null,
        ),
      ),
    );
  }

  Widget _passwordVisibilityButton({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: visible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF94A3B8),
        size: 20,
      ),
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    int step = 1;
    bool loading = false;
    String? sentEmail;
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool showNewPass = false;
    bool showConfirmPass = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE9E4DC),
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          step == 1
                              ? 'استعادة كلمة المرور'
                              : 'تعيين كلمة مرور جديدة',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A4B31),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step == 1
                              ? 'أدخل بريدك الإلكتروني وسنرسل لك كود التحقق'
                              : 'أدخل الكود الذي وصلك على بريدك وكلمة المرور الجديدة',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94a3b8),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                const Color(0xFFD2AF7D).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Color(0xFF9B7E4B), size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2].map((s) {
                    final active = s == step;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 10,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFD2AF7D)
                            : const Color(0xFFE9E4DC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Step 1: Email
                if (step == 1) ...[
                  _buildInput(
                    controller: emailCtrl,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: loading
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                _showSnack('يرجى إدخال بريد إلكتروني صحيح',
                                    error: true);
                                return;
                              }
                              setSheet(() => loading = true);
                              try {
                                await AuthService.instance
                                    .forgotPassword(email: email);
                                sentEmail = email;
                                setSheet(() {
                                  step = 2;
                                  loading = false;
                                });
                              } on ApiException catch (e) {
                                setSheet(() => loading = false);
                                if (mounted) {
                                  _showSnack(e.message, error: true);
                                }
                              } catch (_) {
                                setSheet(() => loading = false);
                                if (mounted) {
                                  _showSnack('تعذر إرسال الكود، تحقق من اتصالك',
                                      error: true);
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFD2AF7D),
                            Color(0xFFE1BE8C),
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD2AF7D)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : const Text(
                                'إرسال كود التحقق',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                      ),
                    ),
                  ),
                ],

                // Step 2: Code + new password
                if (step == 2) ...[
                  _buildInput(
                    controller: codeCtrl,
                    label: 'كود التحقق',
                    icon: Icons.pin_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    controller: newPassCtrl,
                    label: 'كلمة المرور الجديدة',
                    icon: Icons.lock_outline_rounded,
                    isPassword: !showNewPass,
                    suffixIcon: _passwordVisibilityButton(
                      visible: showNewPass,
                      onTap: () => setSheet(() => showNewPass = !showNewPass),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    controller: confirmPassCtrl,
                    label: 'تأكيد كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    isPassword: !showConfirmPass,
                    suffixIcon: _passwordVisibilityButton(
                      visible: showConfirmPass,
                      onTap: () =>
                          setSheet(() => showConfirmPass = !showConfirmPass),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setSheet(() => step = 1),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text(
                        '← إعادة إرسال الكود',
                        style: TextStyle(
                          color: Color(0xFF94a3b8),
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: loading
                          ? null
                          : () async {
                              final code = codeCtrl.text.trim();
                              final newPass = newPassCtrl.text;
                              final confirm = confirmPassCtrl.text;
                              if (code.isEmpty) {
                                _showSnack('يرجى إدخال كود التحقق',
                                    error: true);
                                return;
                              }
                              if (newPass.length < 8) {
                                _showSnack(
                                    'كلمة المرور يجب أن تكون ٨ أحرف على الأقل',
                                    error: true);
                                return;
                              }
                              if (newPass != confirm) {
                                _showSnack('كلمتا المرور غير متطابقتين',
                                    error: true);
                                return;
                              }
                              setSheet(() => loading = true);
                              try {
                                await AuthService.instance
                                    .confirmForgotPassword(
                                  email: sentEmail!,
                                  code: code,
                                  newPassword: newPass,
                                );
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (mounted) {
                                  _showSnack(
                                      'تم تغيير كلمة المرور بنجاح، يمكنك الدخول الآن');
                                }
                              } on ApiException catch (e) {
                                setSheet(() => loading = false);
                                if (mounted) {
                                  _showSnack(e.message, error: true);
                                }
                              } catch (_) {
                                setSheet(() => loading = false);
                                if (mounted) {
                                  _showSnack('تعذر تغيير كلمة المرور',
                                      error: true);
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFD2AF7D),
                            Color(0xFFE1BE8C),
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD2AF7D)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : const Text(
                                'تأكيد وتغيير كلمة المرور',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGuestInquirySheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();
    String? selectedGovernorate;
    final List<String> selectedFeatures = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('البحث والاستعلام عن دار رعاية',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e1b4b))),
                ),
                const SizedBox(height: 4),
                const Text(
                    'اختر المواصفات المطلوبة وسيقوم النظام بالبحث عن الدار المناسبة وإرسال طلبك.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748b),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),

                // Dropdown for Governorate
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFe2e8f0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.03),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(16),
                      hint: const Text('اختر المحافظة',
                          style: TextStyle(
                              color: Color(0xFF94a3b8), fontSize: 15)),
                      value: selectedGovernorate,
                      items: ['القاهرة', 'الجيزة', 'الإسكندرية', 'القليوبية']
                          .map((gov) => DropdownMenuItem(
                                value: gov,
                                child: Text(gov, textAlign: TextAlign.right),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedGovernorate = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInput(
                    controller: cityController,
                    label: 'المنطقة / المدينة',
                    icon: Icons.location_city_outlined),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('المميزات المطلوبة:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e1b4b))),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'رعاية طبية ٢٤ ساعة',
                    'علاج طبيعي',
                    'غرفة فردية',
                    'حديقة ومتنزه',
                    'أنشطة ترفيهية',
                    'وجبات مخصصة'
                  ].map((feature) {
                    final isSelected = selectedFeatures.contains(feature);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedFeatures.remove(feature);
                          } else {
                            selectedFeatures.add(feature);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10b981)
                              : const Color(0xFFf0fdf4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFFd1fae5)),
                        ),
                        child: Text(feature,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF065f46),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildInput(
                    controller: nameController,
                    label: 'الاسم الكامل',
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _buildInput(
                    controller: phoneController,
                    label: 'رقم الهاتف للتواصل',
                    icon: Icons.phone_outlined),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedGovernorate == null ||
                          cityController.text.isEmpty) {
                        showAppPopupNotification(
                          context,
                          message: 'يرجى اختيار المحافظة والمنطقة أولاً',
                          type: AppPopupNotificationType.error,
                        );
                        return;
                      }
                      ref.read(appRiverpod).triggerNotification(
                            title: 'طلب التحاق جديد 📄',
                            body:
                                'طلب استعلام من ${nameController.text} (${phoneController.text}) عن دار في $selectedGovernorate - ${cityController.text} بمميزات: ${selectedFeatures.join('، ')}.',
                            type: 'admin',
                            targetRole: 'إدارة',
                          );
                      final gov = selectedGovernorate!;
                      Navigator.pop(context);
                      _showFacilityResultSheet(
                          context, 'دار الرحمة للمسنين', gov);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('بحث وإرسال الطلب',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFacilityResultSheet(
      BuildContext context, String facilityName, String governorate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('نتيجة البحث الموصى بها',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10b981))),
                SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: Color(0xFF10b981)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(facilityName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1e1b4b))),
                  const SizedBox(height: 12),
                  _buildResultRow(Icons.location_on_outlined,
                      '$governorate - شارع النيل بجوار المستشفى المركزي'),
                  const SizedBox(height: 8),
                  _buildResultRow(
                      Icons.phone_outlined, '01122334455 / 02-33445566'),
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.verified_user_outlined,
                      'مرخصة من وزارة التضامن الاجتماعي (ترخيص رقم ٤٣٢١)'),
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.group_add_outlined,
                      'السعة: ٥٠ سرير (متاح أماكن شاغرة حالياً)'),
                  const SizedBox(height: 8),
                  _buildResultRow(
                      Icons.date_range_outlined, 'سنة التأسيس: ٢٠١٥'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // فتح موقع الدار على خرائط جوجل
                  launchUrl(
                      Uri.parse('https://maps.google.com/?q=30.0444,31.2357'));
                },
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                label: const Text('عرض الموقع على خرائط جوجل',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF94a3b8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('إغلاق',
                    style: TextStyle(
                        color: Color(0xFF64748b),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: const Color(0xFF64748b)),
      ],
    );
  }
}
