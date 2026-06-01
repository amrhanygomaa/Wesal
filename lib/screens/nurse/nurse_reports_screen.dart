import 'package:flutter/material.dart';
import 'widgets/healing_particles.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

class NurseReportsScreen extends ConsumerStatefulWidget {
  const NurseReportsScreen({super.key});

  @override
  ConsumerState<NurseReportsScreen> createState() => _NurseReportsScreenState();
}

class _NurseReportsScreenState extends ConsumerState<NurseReportsScreen>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  String _selectedType = 'تقرير يومي';
  final Map<String, bool> _activeRecipients = {
    'الطبيب المشرف': true,
    'الإدارة': true,
    'الأخصائي': true,
    'الأسر': false,
  };

  String _dailyTime = '٠٨:٠٠ ص';
  String _weeklyDay = 'الجمعة';
  bool _isCriticalAlertOn = true;
  bool _isMissedMedAlertOn = true;

  String _fullArabicDate(DateTime date) {
    const arabicMonths = [
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
      'ديسمبر',
    ];
    return '${date.day} ${arabicMonths[date.month - 1]} ${date.year}';
  }

  /// Returns a human-readable "last sent" label derived from [sentReports].
  String _lastSentLabel(List<SentReport> sentReports) {
    if (sentReports.isEmpty) return 'لم يُرسل بعد';
    DateTime? latestTime;
    for (final r in sentReports) {
      final dt = DateTime.tryParse(r.date);
      if (dt != null && (latestTime == null || dt.isAfter(latestTime))) {
        latestTime = dt;
      }
    }
    if (latestTime == null) return 'تم الإرسال';
    if (latestTime.hour != 0 || latestTime.minute != 0) {
      final h = latestTime.hour;
      final m = latestTime.minute.toString().padLeft(2, '0');
      final period = h < 12 ? 'ص' : 'م';
      final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return 'آخر إرسال $displayH:$m $period';
    }
    return 'آخر إرسال ${latestTime.day}/${latestTime.month}';
  }

  String _getShiftName() {
    int hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'الوردية الصباحية (٦ ص - ٢ ظ)';
    if (hour >= 14 && hour < 22) return 'الوردية المسائية (٢ ظ - ١٠ م)';
    return 'الوردية الليلية (١٠ م - ٦ ص)';
  }

  @override
  void initState() {
    super.initState();

    _blinkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _sendReport(String reportType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFF0EA5E9), strokeWidth: 3),
              const SizedBox(height: 24),
              Text('جاري إرسال $reportType...',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                      decoration: TextDecoration.none,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('يتم الآن تشفير البيانات وإرسالها للجهات المعنية',
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                      decoration: TextDecoration.none,
                      fontFamily: 'Cairo')),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      Navigator.pop(context);

      final provider = ref.read(appRiverpod);
      String icon = '📋';
      if (reportType == 'تقرير أسبوعي') icon = '📊';
      if (reportType == 'تنبيه حرج') icon = '🚨';
      if (reportType == 'تقرير أدوية') icon = '💊';

      final now = DateTime.now();
      final hourStr = now.hour.toString().padLeft(2, '0');
      final minStr = now.minute.toString().padLeft(2, '0');
      await provider.addSentReport(SentReport(
        id: now.millisecondsSinceEpoch.toString(),
        icon: icon,
        title: '$reportType لتاريخ ${_fullArabicDate(now)}',
        meta: 'أُرسل يدوياً · $hourStr:$minStr',
        status: 'أُرسل',
        date: now.toIso8601String(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(provider.backendSyncError ?? 'تم إرسال $reportType بنجاح'),
        backgroundColor: provider.backendSyncError == null
            ? const Color(0xFF10B981)
            : const Color(0xFFef4444),
      ));
    });
  }

  Future<void> _generatePDF(String reportType) async {
    final provider = ref.read(appRiverpod);
    final facility =
        provider.facilityName.isEmpty ? 'المنشأة' : provider.facilityName;
    final nurseName = provider.currentAccount?.name ?? 'فريق التمريض';
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'لا توجد بيانات مقيمين';
    final residentsCount = provider.residentFiles.length;
    final compliance = provider.compliancePercentage;
    final criticalCount = provider.criticalResidentsCount;
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontBoldData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('تطبيق ونس',
                          style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 18,
                              color: PdfColors.blue600)),
                      pw.Text(facility,
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('الممرض: $nurseName',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700)),
                      pw.Text(
                          'التاريخ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  الوقت: ${DateTime.now().hour}:${DateTime.now().minute}',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.blue200, thickness: 2),
                  pw.SizedBox(height: 20),

                  // Title
                  pw.Center(
                    child: pw.Text('تقرير: $reportType',
                        style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 20,
                            color: PdfColors.grey900)),
                  ),
                  pw.SizedBox(height: 30),

                  // Content from the AWS-backed app state.
                  pw.Text('تفاصيل التقرير:',
                      style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 16,
                          color: PdfColors.grey800)),
                  pw.SizedBox(height: 15),

                  if (reportType == 'تقرير أسبوعي') ...[
                    _pdfRow(ttf, ttfBold, 'الأسبوع الحالي', 'آخر ٧ أيام'),
                    _pdfRow(ttf, ttfBold, 'عدد المقيمين', '$residentsCount'),
                    _pdfRow(ttf, ttfBold, 'متوسط الالتزام', '$compliance٪'),
                  ] else if (reportType == 'تنبيه حرج') ...[
                    _pdfRow(ttf, ttfBold, 'المقيم', residentName),
                    _pdfRow(ttf, ttfBold, 'الحالات الحرجة', '$criticalCount'),
                    _pdfRow(ttf, ttfBold, 'مصدر البيانات', 'AWS'),
                  ] else ...[
                    _pdfRow(ttf, ttfBold, 'حالة الوردية', _getShiftName()),
                    _pdfRow(ttf, ttfBold, 'عدد المقيمين المتابعين',
                        '$residentsCount'),
                    _pdfRow(
                        ttf, ttfBold, 'نسبة الالتزام الدوائي', '$compliance٪'),
                  ],

                  pw.Spacer(),

                  // Signature
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                            width: 120,
                            child: pw.Divider(
                                color: PdfColors.grey400, thickness: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text('توقيع الممرض',
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 12,
                                color: PdfColors.grey800)),
                        pw.Text(nurseName,
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 11,
                                color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Footer
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                        'تم إنشاء هذا التقرير تلقائياً عبر تطبيق ونس',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 10, color: PdfColors.grey600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '$reportType.pdf',
    );
  }

  pw.Widget _pdfRow(pw.Font ttf, pw.Font ttfBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: ttfBold, fontSize: 12, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: ttf, fontSize: 12, color: PdfColors.grey900)),
        ],
      ),
    );
  }

  void _showPreviewDialog(String type) {
    String title = 'معاينة $type';
    Widget content;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.read(appRiverpod);
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'لا توجد بيانات مقيمين';
    final residentsCount = provider.residentFiles.length;
    final compliance = provider.compliancePercentage;
    final totalDoses = provider.medications.length;
    final doneDoses = provider.medications.where((m) => m.isTaken).length;
    final pendingDoses = totalDoses - doneDoses;
    if (type == 'تقرير أسبوعي') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _previewRow('الأسبوع الحالي', 'آخر ٧ أيام'),
          _previewRow('عدد المقيمين', '$residentsCount'),
          _previewRow('متوسط الالتزام', '$compliance٪'),
          Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
          Text('تقرير الاتجاهات:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87)),
          Text('• البيانات المعروضة محملة من AWS حسب آخر مزامنة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ],
      );
    } else if (type == 'تنبيه حرج') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️ سيتم إرسال تنبيه فوري للطبيب المشرف والإدارة',
              style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 12),
          _previewRow('المقيم', residentName),
          _previewRow('الحالات الحرجة', '${provider.criticalResidentsCount}'),
          _previewRow('مصدر البيانات', 'AWS'),
        ],
      );
    } else if (type == 'تقرير أدوية') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _previewRow('إجمالي الجرعات اليوم', '$totalDoses جرعة'),
          _previewRow('جرعات منفذة', '$doneDoses جرعة'),
          _previewRow('جرعات متبقية', '$pendingDoses جرعة'),
          Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
          Text('تفاصيل الجرعات المعلقة:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87)),
          Text('• راجع جدول الأدوية المحمل من AWS للتفاصيل.',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ],
      );
    } else {
      // Daily
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _previewRow('تاريخ التقرير',
              DateTime.now().toIso8601String().split('T').first),
          _previewRow('عدد المقيمين', '$residentsCount مقيم'),
          _previewRow('حالات حرجة', '${provider.criticalResidentsCount} حالة'),
          _previewRow('الالتزام بالأدوية', '$compliance٪'),
          Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
          Text('أهم الملاحظات:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87)),
          Text('• أهم الملاحظات ستظهر حسب بيانات AWS المتاحة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black87)),
        content: SingleChildScrollView(child: content),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendReport(type);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'تنبيه حرج'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0EA5E9),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('إرسال الآن',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generatePDF(type);
                  },
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0EA5E9)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('تحميل PDF',
                      style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء',
                      style: TextStyle(
                          color:
                              isDark ? Colors.white38 : const Color(0xFF64748B),
                          fontFamily: 'Cairo')),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0EA5E9))),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 10),
                _buildQuickSendCard(),
                const SizedBox(height: 10),
                _buildCriticalNotif(),
                const SizedBox(height: 10),
                _buildReportTypes(),
                const SizedBox(height: 10),
                _buildRecipients(),
                const SizedBox(height: 10),
                _buildScheduleSettings(),
                const SizedBox(height: 10),
                _buildReportCompleteness(),
                const SizedBox(height: 10),
                _buildSentHistory(),
                const SizedBox(height: 20),
                const SizedBox(height: 100), // Space for parent's bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    final provider = ref.watch(appRiverpod);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
        ),
      ),
      child: Stack(
        children: [
          const HealingParticles(), // الأنيميشن الموحد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📤 التقارير والإرسال',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.currentAccount?.name ?? 'فريق التمريض'} — ${_getShiftName()}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: Tween<double>(begin: 0.15, end: 1.0)
                                .animate(_blinkController),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4ADE80)),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('إرسال تلقائي يومي $_dailyTime — مفعّل',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSendCard() {
    final provider = ref.watch(appRiverpod);
    final residentsCount = provider.residentFiles.length;
    final criticalCount = provider.criticalResidentsCount;
    final compliance = provider.compliancePercentage;
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -3 * _floatController.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -34,
                    top: -34,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('التقرير اليومي جاهز',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.8))),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(
                                          alpha: 0.4 * _pulseController.value),
                                      blurRadius: 7 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Text('✓',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text(_lastSentLabel(provider.sentReports),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text('تقرير الوردية الصباحية',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                          '$residentsCount مقيم · $criticalCount حالة حرجة · $compliance٪ التزام بالأدوية',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9))),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showPreviewDialog('التقرير اليومي'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.remove_red_eye_outlined,
                                        color: Color(0xFF0369A1), size: 14),
                                    SizedBox(width: 5),
                                    Text('معاينة',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0369A1))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _sendReport('التقرير اليومي'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded,
                                        color: Colors.white, size: 13),
                                    SizedBox(width: 5),
                                    Text('إرسال الآن',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCriticalNotif() {
    final provider = ref.watch(appRiverpod);
    final criticalResident = provider.residentFiles
        .where((resident) =>
            resident.status.toLowerCase().contains('critical') ||
            resident.status.contains('حرج'))
        .toList();
    if (criticalResident.isEmpty) return const SizedBox.shrink();
    final resident = criticalResident.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.15, end: 1.0)
                  .animate(_blinkController),
              child: const Text('🚨', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إرسال تنبيه حرج — ${resident.name}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 1),
                  Text('غرفة ${resident.room} · الحالة من AWS',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _sendReport('التنبيه الحرج'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('إرسال',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0369A1))),
        ],
      ),
    );
  }

  Widget _buildReportTypes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _sectionHeader('نوع التقرير', const Color(0xFF0EA5E9)),
          Row(
            children: [
              Expanded(
                  child: _rTypeCard('📋', 'تقرير يومي', 'ملخص كامل للوردية',
                      _selectedType == 'تقرير يومي', () {
                setState(() => _selectedType = 'تقرير يومي');
                _showPreviewDialog('تقرير يومي');
              })),
              const SizedBox(width: 8),
              Expanded(
                  child: _rTypeCard('📊', 'تقرير أسبوعي', 'اتجاهات ومقارنات',
                      _selectedType == 'تقرير أسبوعي', () {
                setState(() => _selectedType = 'تقرير أسبوعي');
                _showPreviewDialog('تقرير أسبوعي');
              })),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _rTypeCard('🚨', 'تنبيه حرج', 'إرسال فوري للحالات',
                      _selectedType == 'تنبيه حرج', () {
                setState(() => _selectedType = 'تنبيه حرج');
                _showPreviewDialog('تنبيه حرج');
              })),
              const SizedBox(width: 8),
              Expanded(
                  child: _rTypeCard('💊', 'تقرير أدوية', 'الالتزام والجرعات',
                      _selectedType == 'تقرير أدوية', () {
                setState(() => _selectedType = 'تقرير أدوية');
                _showPreviewDialog('تقرير أدوية');
              })),
            ],
          )
        ],
      ),
    );
  }

  Widget _rTypeCard(
      String icon, String title, String desc, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: active
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
              color: active
                  ? Colors.transparent
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              width: 1.5),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.2)
                        : (isDark ? Colors.white10 : const Color(0xFFF0F9FF)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.white
                            : (isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)))),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? Colors.white.withValues(alpha: 0.8)
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF475569)))),
              ],
            ),
            if (active)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Icon(Icons.check,
                          size: 12, color: Color(0xFF0EA5E9))),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipients() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('المستلمون', const Color(0xFF7C3AED)),
            _recRow('د.أ', const Color(0xFFDBEAFE), const Color(0xFF1E40AF),
                'الطبيب المشرف', 'يستلم: الحرجة + اليومي', 'الطبيب المشرف'),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 12),
            _recRow('إد', const Color(0xFFEDE9FE), const Color(0xFF4C1D95),
                'الإدارة العامة', 'يستلم: الأسبوعي فقط', 'الإدارة'),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 12),
            _recRow('أس', const Color(0xFFD1FAE5), const Color(0xFF065F46),
                'الأخصائي الاجتماعي', 'يستلم: الحرجة النفسية', 'الأخصائي'),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 12),
            _recRow('أس', const Color(0xFFFEF3C7), const Color(0xFF92400E),
                'أسر المقيمين', 'يستلمون: التقرير الأسبوعي', 'الأسر'),
          ],
        ),
      ),
    );
  }

  Widget _recRow(
      String av, Color bg, Color fg, String n, String r, String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isOn = _activeRecipients[key] ?? false;
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: isDark ? bg.withValues(alpha: 0.2) : bg,
          child: Text(av,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? fg.withValues(alpha: 0.8) : fg)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 1),
              Text(r,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF475569))),
            ],
          ),
        ),
        _toggle(isOn, () {
          setState(() {
            _activeRecipients[key] = !isOn;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isOn
                ? 'تم إيقاف الإرسال لـ $key 🛑'
                : 'تم تفعيل الإرسال لـ $key'),
            duration: const Duration(seconds: 1),
          ));
        }),
      ],
    );
  }

  Widget _toggle(bool on, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: on
              ? const Color(0xFF0EA5E9)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              top: 2,
              left: on ? 18 : 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: isDark
                        ? (on ? Colors.white : Colors.white38)
                        : Colors.white,
                    shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('إعدادات الجدول التلقائي', const Color(0xFF10B981)),
            _schRowVal(
                'التقرير اليومي', 'يُرسل تلقائياً نهاية الوردية', _dailyTime,
                () async {
              final picked = await showTimePicker(
                  context: context, initialTime: TimeOfDay.now());
              if (picked != null) {
                setState(() => _dailyTime = picked.format(context));
              }
            }),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 14),
            _schRowVal('التقرير الأسبوعي', 'كل جمعة تلقائياً', _weeklyDay, () {
              _showDayPicker();
            }),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 14),
            _schRowTog('تنبيه القراءات الحرجة', 'إرسال فوري عند تجاوز الحد',
                _isCriticalAlertOn, (val) {
              setState(() => _isCriticalAlertOn = val);
            }),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 14),
            _schRowTog('تنبيه الدواء الفائت', 'بعد ٣٠ دقيقة من الموعد',
                _isMissedMedAlertOn, (val) {
              setState(() => _isMissedMedAlertOn = val);
            }),
          ],
        ),
      ),
    );
  }

  void _showDayPicker() {
    final days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة'
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر يوم التقرير الأسبوعي',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: days
              .map((d) => ListTile(
                    title: Text(d,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontFamily: 'Cairo')),
                    onTap: () {
                      setState(() => _weeklyDay = d);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _schRowVal(String lbl, String sub, String val, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lbl,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 1),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8)),
            child: Text(val,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1))),
          )
        ],
      ),
    );
  }

  Widget _schRowTog(String lbl, String sub, bool on, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lbl,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 1),
            Text(sub,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged(!on),
              child: Container(
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                    color: on
                        ? const Color(0xFF0EA5E9)
                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(9)),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      top: 2,
                      left: on ? 14 : 2,
                      child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(on ? 'مفعّل' : 'معطّل',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: on
                        ? (isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0369A1))
                        : (isDark ? Colors.white38 : const Color(0xFF64748B)))),
          ],
        )
      ],
    );
  }

  Widget _buildReportCompleteness() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('اكتمال التقرير اليومي', const Color(0xFF0EA5E9)),
            const SizedBox(height: 4),
            _progRow(
                'القراءات الحيوية', '٨٧٪', 0.87, const Color(0xFF0EA5E9), 900),
            const SizedBox(height: 9),
            _progRow(
                'تأكيد الأدوية', '٩٢٪', 0.92, const Color(0xFF10B981), 1500),
            const SizedBox(height: 9),
            _progRow(
                'ملاحظات الممرضة', '٦٠٪', 0.60, const Color(0xFFF59E0B), 1600),
            const SizedBox(height: 7),
            const Text('أكمل الملاحظات الناقصة قبل إرسال التقرير',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _progRow(String title, String val, double pct, Color c, int delay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text(val,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: c)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 7,
          decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6)),
          child: Align(
            alignment: Alignment.centerRight,
            child: TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0, end: pct),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSentHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.watch(appRiverpod);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('سجل الإرسال ', const Color(0xFF10B981)),
          const SizedBox(height: 8),
          if (provider.sentReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 40,
                    color: isDark ? Colors.white30 : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا يوجد سجل إرسال حتى الآن',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.sentReports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final report = provider.sentReports[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0.0, 20.0 * (1.0 - value).clamp(-1.0, 1.0)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildSentReportCard(report),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSentReportCard(SentReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Determine category colors and icons
    Color categoryColor = const Color(0xFF10B981); // Emerald (Daily)
    IconData cardIcon = Icons.assignment_turned_in_rounded;
    IconData metaIcon = Icons.info_outline_rounded;

    if (report.title.contains('حرج') || report.icon == '🚨') {
      categoryColor = const Color(0xFFEF4444); // Red (Critical Alert)
      cardIcon = Icons.emergency_rounded;
      metaIcon = Icons.bolt_rounded;
    } else if (report.title.contains('أسبوعي') || report.icon == '📊') {
      categoryColor = const Color(0xFF8B5CF6); // Purple (Weekly)
      cardIcon = Icons.analytics_rounded;
      metaIcon = Icons.calendar_month_rounded;
    } else if (report.status == 'مجدول') {
      categoryColor = const Color(0xFFF59E0B); // Amber (Scheduled)
      cardIcon = Icons.calendar_today_rounded;
      metaIcon = Icons.schedule_rounded;
    }

    // Dynamic meta icon override
    if (report.meta.contains('تلقائياً')) {
      metaIcon = Icons.autorenew_rounded;
    } else if (report.meta.contains('يدوياً')) {
      metaIcon = Icons.send_rounded;
    } else if (report.meta.contains('مجدول')) {
      metaIcon = Icons.schedule_rounded;
    }

    // 2. Parse title for beautiful visual hierarchy
    String mainTitle = report.title;
    String subtitle = '';
    if (report.title.contains('—')) {
      final parts = report.title.split('—');
      mainTitle = parts[0].trim();
      subtitle = parts[1].trim();
    } else if (report.title.contains(' - ')) {
      final parts = report.title.split(' - ');
      mainTitle = parts[0].trim();
      subtitle = parts[1].trim();
    }

    // 3. Status Badge colors
    Color statusBg = isDark
        ? const Color(0xFF065F46).withValues(alpha: 0.15)
        : const Color(0xFFE6FDF5);
    Color statusFg = const Color(0xFF059669);
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (report.status == 'مجدول') {
      statusBg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.15)
          : const Color(0xFFFFFBEB);
      statusFg = const Color(0xFFD97706);
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 4. Accent line indicator on the right side (RTL friendly)
              Container(
                width: 5,
                color: categoryColor,
              ),

              // Card content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // 5. Styled Glowing Icon Container
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(
                              alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor.withValues(
                                alpha: isDark ? 0.25 : 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            cardIcon,
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 6. Report info (Title & Meta)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  mainTitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '•  $subtitle',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  metaIcon,
                                  size: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    report.meta,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 7. Dynamic Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusFg.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 11,
                              color: statusFg,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              report.status,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusFg,
                              ),
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
        ),
      ),
    );
  }
}
