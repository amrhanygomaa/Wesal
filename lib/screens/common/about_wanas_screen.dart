import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';

class AboutWanasScreen extends ConsumerWidget {
  const AboutWanasScreen({super.key});

  static List<Color> _roleGradient(String role) {
    switch (role) {
      case 'ممرض':
        return [const Color(0xFF0369A1), const Color(0xFF0EA5E9), const Color(0xFF38BDF8)];
      case 'متطوع':
        return [const Color(0xFF064e3b), const Color(0xFF059669), const Color(0xFF10b981)];
      case 'عائلة':
      case 'أخصائي':
        return [const Color(0xFFc2410c), const Color(0xFFea580c), const Color(0xFFf97316)];
      case 'مدير':
      case 'إدارة':
        return [const Color(0xFF0f172a), const Color(0xFF1e293b), const Color(0xFF334155)];
      case 'مسن':
      default:
        return [const Color(0xFF1a0533), const Color(0xFF3730a3), const Color(0xFF6C63FF)];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRiverpod).currentRole;
    final gradient = _roleGradient(role);
    final headerStart = gradient[0];
    final headerEnd = gradient[gradient.length - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: headerStart,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text(
                'عن ونس',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28)),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      left: -30,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Logo centred in expanded area
                    Positioned(
                      top: 52,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: headerEnd.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/wanas_logo.png',
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text(
                                  'ونس',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body content ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // App name + version
                Text(
                  'تطبيق ونس للرعاية الذكية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: headerStart,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'الإصدار 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94a3b8),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 28),

                _SectionCard(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFef4444),
                  accentColor: headerStart,
                  title: 'رسالتنا',
                  body: 'توفير رعاية ذكية ومتكاملة لكبار السن من خلال التكنولوجيا والذكاء الاصطناعي، وتعزيز التواصل بينهم وبين عائلاتهم ومقدمي الرعاية.',
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  icon: Icons.lightbulb_rounded,
                  iconColor: const Color(0xFFf59e0b),
                  accentColor: headerStart,
                  title: 'رؤيتنا',
                  body: 'عالم يشعر فيه كل مقيم بالأمان والاهتمام والتواصل مع عائلته، حيث تُستخدم التقنية لإثراء حياة كبار السن لا لتعقيدها.',
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFF6C63FF),
                  accentColor: headerStart,
                  title: 'مميزات التطبيق',
                  body: '• رفيق الذكاء الاصطناعي — يتحدث ويستمع ويتذكر\n'
                      '• متابعة الأدوية والمواعيد الصحية\n'
                      '• ألعاب ذهنية لتنشيط الذاكرة\n'
                      '• تواصل مباشر مع الأسرة\n'
                      '• تقارير يومية لمقدمي الرعاية\n'
                      '• جدولة الزيارات والفعاليات',
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFF059669),
                  accentColor: headerStart,
                  title: 'تواصل معنا',
                  body: 'البريد الإلكتروني: support@wanas.sa\nالهاتف: 920‑000‑0000\nالموقع: www.wanas.sa',
                ),
                const SizedBox(height: 28),

                const Text(
                  '© 2024 ونس — جميع الحقوق محفوظة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94a3b8),
                      fontFamily: 'Cairo'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color accentColor;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.7,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
