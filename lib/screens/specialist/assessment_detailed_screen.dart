import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart'; // مزود الحالة العام
import '../../models/app_models.dart'; // نماذج البيانات
import '../../services/pdf_service.dart'; // خدمة إنشاء ملفات PDF
import 'package:lottie/lottie.dart';

// شاشة التقييم الاجتماعي التفصيلي للمقيم - تسمح للأخصائي بإجراء التقييمات وحفظ النتائج
class AssessmentDetailedScreen extends ConsumerStatefulWidget {
  final SocialSpecialistAssessmentTool?
      tool; // أداة التقييم المختارة (نفسي، اجتماعي، إلخ)
  final SocialSpecialistResidentScore
      resident; // بيانات المقيم المستهدف بالتقييم
  final List<AssessmentQuestion>? initialQuestions; // الأسئلة المختارة مسبقاً
  const AssessmentDetailedScreen(
      {super.key, this.tool, required this.resident, this.initialQuestions});

  @override
  ConsumerState<AssessmentDetailedScreen> createState() =>
      _AssessmentDetailedScreenState();
}

class _AssessmentDetailedScreenState
    extends ConsumerState<AssessmentDetailedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController; // متحكم حركات الظهور
  late AnimationController _ringController; // متحكم حركات الحلقات
  late AnimationController _shimmerController; // متحكم حركة اللمعان
  late List<Animation<double>> _fadeAnimations; // قائمة الحركات المتسلسلة
  int _currentToolIndex = 0; // الفهرس الحالي للأداة
  int _questionIndex = 0; // الفهرس الحالي للسؤال
  final Map<int, int> _selections = {}; // تخزين الإجابات المختارة
  final Map<int, int> _scales = {}; // تخزين إجابات المقاييس الرقمية
  final Set<String> _activeNotes = {}; // تخزين الملاحظات المفعلة
  late List<AssessmentQuestion> _questions; // قائمة الأسئلة الحالية
  bool _isLoadingQuestions = true;
  final TextEditingController _notesController = TextEditingController(
      text: 'المقيم يُبدي علامات قلق متزايدة مؤخراً...'); // متحكم نص الملاحظات
  bool _isInterventionRequired = false; // حالة التدخل الاجتماعي

  @override
  void initState() {
    super.initState();

    _questions = [];

    // إعداد الـ Animations
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _fadeAnimations = List.generate(12, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _fadeController,
            curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut)),
      );
    });

    _fadeController.forward();
    _ringController.forward();

    // تحميل الأسئلة بعد أول frame حتى لا يتعطل فتح الشاشة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ringController.dispose();
    _shimmerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  SocialSpecialistAssessmentTool? _resolvedTool(AppRiverpod provider) {
    if (widget.tool != null) return widget.tool;
    if (provider.socialAssessmentTools.isNotEmpty) {
      return provider.socialAssessmentTools.first;
    }
    return null;
  }

  AssessmentQuestion _questionFromMap(Map<String, dynamic> q, int index) {
    final options = q['options'];
    return AssessmentQuestion(
      id: q['id']?.toString().isNotEmpty == true
          ? q['id'].toString()
          : 'q$index',
      text: (q['text'] ?? q['question'] ?? '').toString(),
      type: (q['type'] ?? 'scale').toString(),
      options:
          options is List ? options.map((e) => e.toString()).toList() : null,
    );
  }

  Future<void> _loadQuestions() async {
    if (widget.initialQuestions != null) {
      if (!mounted) return;
      setState(() {
        _questions = widget.initialQuestions!
            .where((q) => q.text.trim().isNotEmpty)
            .take(AppRiverpod.maxAssessmentQuestionsPerCategory)
            .toList();
        _questionIndex = 0;
        _isLoadingQuestions = false;
      });
      return;
    }

    final provider = ref.read(appRiverpod);
    final tool = _resolvedTool(provider);
    var rawQuestions = tool == null
        ? <Map<String, dynamic>>[]
        : provider.getQuestionsForAssessmentTool(tool);

    if (rawQuestions.isEmpty && tool != null && tool.id.trim().isNotEmpty) {
      await provider.loadQuestionsForTool(tool.id);
      rawQuestions = provider.getQuestionsForAssessmentTool(tool);
    }

    var loaded = rawQuestions
        .asMap()
        .entries
        .map((entry) {
          return _questionFromMap(entry.value, entry.key);
        })
        .where((q) => q.text.trim().isNotEmpty)
        .take(AppRiverpod.maxAssessmentQuestionsPerCategory)
        .toList();

    if (loaded.isEmpty && provider.gdsQuestions.isNotEmpty) {
      loaded = List<AssessmentQuestion>.from(provider.gdsQuestions)
          .take(AppRiverpod.maxAssessmentQuestionsPerCategory)
          .toList();
    }

    if (!mounted) return;
    setState(() {
      _questions = loaded;
      _questionIndex = 0;
      _isLoadingQuestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHero(provider), // الواجهة العلوية (اسم المقيم)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildScoreOverview(), // ملخص الدرجات والتقدم
                  const SizedBox(height: 16),
                  _buildQuestionnaire(provider), // منطقة الأسئلة والتقرير
                  const SizedBox(height: 20),
                  _buildHistoryComparison(
                      provider), // مقارنة مع التقييمات السابقة
                  const SizedBox(height: 20),
                  _buildSpecialistNotes(),
                  const SizedBox(height: 20),
                  _buildAiRecommendationsCard(provider),
                  const SizedBox(height: 20),
                  _buildInterventionToggle(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          _buildActionBar(), // شريط الأزرار السفلي (حفظ)
        ],
      ),
    );
  }

  // بناء الترويسة العلوية التي تظهر بيانات المقيم بشكل متطور وفاخر للغاية
  Widget _buildHero(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C1D04), Color(0xFFEA580C), Color(0xFFFF7A45)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33EA580C),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'أخصائي اجتماعي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'التقييم التفصيلي',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أ. نور — الأخصائية الاجتماعية',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnimations[1],
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFFFEFEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.resident.initials,
                        style: const TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.resident.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.meeting_room_rounded,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'غرفة ${widget.resident.room}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'آخر تقييم: ٣ أشهر',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFD97706).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'يحتاج تجديد',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء تبويبات التبديل بين أنواع التقييمات
  // ignore: unused_element
  Widget _buildToolTabs() {
    final tools = [
      {
        'label': 'نفسي',
        'icon': '🧠',
        'score': '٨/١٥',
        'col': const Color(0xFFf59e0b),
        'bg': const Color(0xFFfef3c7)
      },
      {
        'label': 'اجتماعي',
        'icon': '🤝',
        'score': '٥/٢٠',
        'col': const Color(0xFFef4444),
        'bg': const Color(0xFFfee2e2)
      },
      {
        'label': 'بدني',
        'icon': '🏃',
        'score': '٧٨/١٠٠',
        'col': const Color(0xFF10b981),
        'bg': const Color(0xFFd1fae5)
      },
      {
        'label': 'جودة الحياة',
        'icon': '❤️',
        'score': '٦٢/١٠٠',
        'col': const Color(0xFFf59e0b),
        'bg': const Color(0xFFfef3c7)
      },
    ];

    return Container(
      height: 44,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: List.generate(tools.length, (index) {
            final isAct = _currentToolIndex == index;
            final tool = tools[index];
            return GestureDetector(
              onTap: () => setState(() => _currentToolIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: isAct
                                ? const Color(0xFFea580c)
                                : Colors.transparent,
                            width: 2.5))),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: tool['bg'] as Color,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(tool['score'] as String,
                          style: TextStyle(
                              color: tool['col'] as Color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Text('${tool['icon']} ${tool['label']}',
                        style: TextStyle(
                            color: isAct
                                ? const Color(0xFFea580c)
                                : const Color(0xFF94a3b8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // بناء ملخص الدرجات الحالية والتقدم في التقييم
  Widget _buildScoreOverview() {
    return FadeTransition(
      opacity: _fadeAnimations[2],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تقييم الحالة النفسية GDS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA580C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'مؤشر اكتئاب متوسط · يحتاج متابعة',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFEA580C),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSubScoreBar(
                      'المزاج العام', 0.40, const Color(0xFFF59E0B)),
                  _buildSubScoreBar(
                      'مستوى الطاقة', 0.30, const Color(0xFFEF4444)),
                  _buildSubScoreBar(
                      'مؤشر التفاؤل', 0.65, const Color(0xFF10B981)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 0.53,
                      strokeWidth: 8,
                      backgroundColor: Color(0xFFFFEFEA),
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '٨',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C2D12),
                          fontFamily: 'Cairo',
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'من ١٥',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF7C2D12).withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          height: 1.1,
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
    );
  }

  // بناء شريط التقدم الصغير للدرجات الفرعية مع تدرجات لونية ممتازة
  Widget _buildSubScoreBar(String label, double val, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, maxWidth: 70),
            child: Text(
              label,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: val,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [col, col.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${(val * 100).toInt()}%',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: col,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء منطقة الأسئلة وتوليد التقارير
  Widget _buildQuestionnaire(AppRiverpod provider) {
    final tool = _resolvedTool(provider);
    if (tool == null) {
      return _buildQuestionsEmptyState();
    }
    if (_isLoadingQuestions) {
      return _buildQuestionsLoadingState(title: tool.name);
    }
    if (_questionIndex >= _questions.length && _questions.isNotEmpty) {
      _questionIndex = _questions.length - 1;
    }
    if (_questions.isEmpty) {
      return _buildQuestionsEmptyState(title: tool.name);
    }
    final progress =
        ((_questionIndex + 1) / _questions.length).clamp(0.0, 1.0).toDouble();

    return FadeTransition(
      opacity: _fadeAnimations[3],
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // الترويسة الداخلية للأسئلة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8C1D04), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      tool.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_questionIndex + 1} / ${_questions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // شريط تقدم الأسئلة المتحرك
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  height: 5,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.25),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF8C69),
                            const Color(0xFFEA580C).withValues(
                                alpha: 0.8 +
                                    0.2 *
                                        sin(_shimmerController.value * 2 * pi)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // عرض السؤال الحالي
            Builder(builder: (context) {
              final q = _questions[_questionIndex];
              return _buildQuestionItem(
                'السؤال ${_questionIndex + 1} من ${_questions.length}',
                q.text,
                type: q.type,
                options: q.options,
                selected: _selections[_questionIndex],
                onSelected: (idx) =>
                    setState(() => _selections[_questionIndex] = idx),
                selectedScale: _scales[_questionIndex],
                onScaleSelected: (val) =>
                    setState(() => _scales[_questionIndex] = val),
              );
            }),
            const SizedBox(height: 24),
            // زر توليد تقرير PDF المطور كلياً
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PdfService.generateAssessmentReport(
                        widget.resident, tool, _selections, _questions);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      size: 20, color: Colors.white),
                  label: const Text(
                    'تحميل التقرير كـ PDF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildQuestionNav(), // أزرار التنقل (التالي/السابق)
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsEmptyState({String? title}) {
    return FadeTransition(
      opacity: _fadeAnimations[3],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_late_rounded,
                  color: Color(0xFFEA580C), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'أسئلة التقييم غير متاحة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'لم يتم تحميل أسئلة هذه الأداة من الخادم بعد. جرّب تحديث البيانات أو اختر أداة تقييم أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.6,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsLoadingState({String? title}) {
    return FadeTransition(
      opacity: _fadeAnimations[3],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Color(0xFFEA580C),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title == null
                  ? 'جاري تجهيز أسئلة التقييم...'
                  : 'جاري تجهيز $title...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء عنصر السؤال الفردي بأسلوب فاخر وعصري للغاية
  Widget _buildQuestionItem(
    String num,
    String text, {
    required String type,
    List<String>? options,
    int? selected,
    int? selectedScale,
    Function(int)? onSelected,
    Function(int)? onScaleSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 14,
                  color: const Color(0xFFEA580C).withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                num,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEA580C),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.6,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 24),
          // عرض الخيارات المتعددة
          if (type == 'choice' && options != null)
            Column(
              children: List.generate(options.length, (index) {
                final isSel = selected == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onSelected?.call(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFFFF5F2) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFFFF7A45)
                              : const Color(0xFFF1F5F9),
                          width: isSel ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSel
                                ? const Color(0xFFEA580C).withValues(alpha: 0.1)
                                : const Color(0xFF0F172A)
                                    .withValues(alpha: 0.03),
                            blurRadius: isSel ? 12 : 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                              color: isSel
                                  ? const Color(0xFFEA580C)
                                  : Colors.transparent,
                            ),
                            child: isSel
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                color: isSel
                                    ? const Color(0xFFC2410C)
                                    : const Color(0xFF1E293B),
                                fontSize: 14,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          // عرض المقياس الرقمي (1-5) المطور
          if (type == 'scale')
            Row(
              children: [
                const Text(
                  'ممتاز',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final i = 5 - index;
                      final isSel = selectedScale == i;
                      return GestureDetector(
                        onTap: () => onScaleSelected?.call(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSel ? null : const Color(0xFFF8FAFC),
                            gradient: isSel
                                ? const LinearGradient(colors: [
                                    Color(0xFFEA580C),
                                    Color(0xFFFF7A45)
                                  ])
                                : null,
                            shape: BoxShape.circle,
                            border: isSel
                                ? null
                                : Border.all(
                                    color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEA580C)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$i',
                              style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Text(
                  'ضعيف',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          // عرض رد نصي افتراضي
          if (type == 'text')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'المقيم ذكر شعوره بالعجز في بعض المواقف اليومية البسيطة والأنشطة المشتركة مع زملائه بالدار...',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                  height: 1.6,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // بناء أزرار التنقل بين الأسئلة بأيقونات متناسقة مع اللغة العربية (RTL)
  Widget _buildQuestionNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر التالي على اليمين في اللغة العربية (RTL: التالي = اتجاه اليمين)
          GestureDetector(
            onTap: () => setState(() {
              if (_questionIndex < _questions.length - 1) _questionIndex++;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD8C2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'التالي',
                      style: TextStyle(
                        color: Color(0xFFC2410C),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Color(0xFFC2410C)),
                  ],
                ),
              ),
            ),
          ),
          Text(
            '${_questionIndex + 1} من ${_questions.length}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
          // زر السابق على اليسار في اللغة العربية (RTL: السابق = اتجاه اليسار)
          GestureDetector(
            onTap: () => setState(() {
              if (_questionIndex > 0) _questionIndex--;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 18, color: Color(0xFF475569)),
                    SizedBox(width: 6),
                    Text(
                      'السابق',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء مقارنة التقييمات التاريخية برسومات وجداول ملونة وجميلة
  Widget _buildHistoryComparison(AppRiverpod provider) {
    return FadeTransition(
      opacity: _fadeAnimations[4],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'سجل ومقارنة التقييمات السابقة',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: provider.assessmentHistory
                  .map((h) => _buildCompareRow(h))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // بناء صف المقارنة الفردي بنظام تدرج ونقاط ذكية
  Widget _buildCompareRow(AssessmentHistoricalEntry h) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _buildTrendArrow(h.trend), // سهم الاتجاه المطور
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${h.score.toInt()}/${h.total}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEA580C),
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: h.score / (double.tryParse(h.total) ?? 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFFF7A45)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 85,
            child: Text(
              h.date,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // إرجاع أيقونة الاتجاه المناسبة بشكل جمالي
  Widget _buildTrendArrow(String trend) {
    if (trend == 'up') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFFD1FAE5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.trending_up_rounded,
          color: Color(0xFF10B981),
          size: 16,
        ),
      );
    }
    if (trend == 'down') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFFFEE2E2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.trending_down_rounded,
          color: Color(0xFFEF4444),
          size: 16,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.trending_flat_rounded,
        color: Color(0xFF94A3B8),
        size: 16,
      ),
    );
  }

  // بناء منطقة ملاحظات الأخصائي مع الكلمات الدلالية (Tags) الملونة والمنعشة
  Widget _buildSpecialistNotes() {
    final tags = [
      'متابعة شهرية',
      'جلسة أسبوعية',
      'تنسيق مع الأسرة',
      'يحتاج دعم نفسي'
    ];
    return FadeTransition(
      opacity: _fadeAnimations[5],
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA580C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'توصيات وملاحظات الأخصائية',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                )
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                  height: 1.6,
                  fontFamily: 'Cairo',
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'اكتب ملاحظاتك وتوجيهاتك السريرية...',
                  hintStyle:
                      TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: tags
                  .map((t) => GestureDetector(
                        onTap: () => setState(() {
                          if (_activeNotes.contains(t)) {
                            _activeNotes.remove(t);
                          } else {
                            _activeNotes.add(t);
                          }
                        }),
                        child: _NoteChip('+ $t',
                            isSelected: _activeNotes.contains(t)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiRecommendationsCard(AppRiverpod provider) {
    final residentId = _resolvedResidentId(provider);
    final insights = provider.aiInsights
        .where((i) =>
            i.residentId == residentId ||
            i.residentName.contains(widget.resident.name.split(' ').first))
        .toList();
    final feedback = provider.aiInsightError;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('توصيات الذكاء الاصطناعي',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b))),
                ),
                if (provider.isLoadingAiInsight)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6366F1)))
                else
                  GestureDetector(
                    onTap: () => _refreshAiRecommendations(
                      provider,
                      residentId,
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF6366F1), size: 20),
                  ),
              ],
            ),
          ),
          const Divider(height: 20),
          if (feedback != null && feedback.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _buildAiFeedbackBanner(
                feedback,
                isError: provider.aiInsightMode == 'error',
              ),
            ),
          if (insights.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF94a3b8), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.isLoadingAiInsight
                          ? 'جاري تحميل التوصيات...'
                          : 'اضغط على أيقونة التحديث لجلب توصيات الذكاء الاصطناعي',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94a3b8)),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: insights.map((insight) {
                  final isCritical = insight.type == 'predictive_alert';
                  final color = isCritical
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF6366F1);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCritical
                                  ? Icons.warning_amber_rounded
                                  : Icons.lightbulb_outline_rounded,
                              color: color,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(isCritical ? 'تنبيه حرج' : 'توصية',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(stripUuids(insight.summary),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                                height: 1.5)),
                        if (stripUuids(insight.rationale).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(stripUuids(insight.rationale),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748b),
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _resolvedResidentId(AppRiverpod provider) {
    final direct = widget.resident.id.trim();
    if (provider.residentFiles.any((r) => r.id == direct)) return direct;
    for (final resident in provider.residentFiles) {
      if (resident.name.trim() == widget.resident.name.trim() ||
          (widget.resident.room.isNotEmpty &&
              resident.room == widget.resident.room)) {
        return resident.id;
      }
    }
    return direct;
  }

  Future<void> _refreshAiRecommendations(
    AppRiverpod provider,
    String residentId,
  ) async {
    final ok =
        await provider.refreshAiInsightFromBackend(residentId: residentId);
    if (!mounted) return;
    final message = ok
        ? (provider.aiInsightMode == 'fallback'
            ? 'تم عرض توصية احتياطية لحين عودة خدمة الذكاء الاصطناعي'
            : 'تم جلب توصيات الذكاء الاصطناعي')
        : (provider.aiInsightError ?? 'تعذر جلب توصيات الذكاء الاصطناعي');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: ok ? const Color(0xFF6366F1) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAiFeedbackBanner(String message, {required bool isError}) {
    final color = isError ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: color,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء خيار تفعيل التدخل الاجتماعي العاجل
  Widget _buildInterventionToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isInterventionRequired ? const Color(0xFFFFF1F1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isInterventionRequired
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isInterventionRequired
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF0F172A))
                .withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.report_problem_rounded,
                color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب تدخل علاجي عاجل',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'سيتم إخطار الطاقم الطبي والإدارة فوراً',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isInterventionRequired,
            onChanged: (v) => setState(() => _isInterventionRequired = v),
            activeThumbColor: const Color(0xFFEF4444),
            activeTrackColor: const Color(0xFFFCA5A5),
          ),
        ],
      ),
    );
  }

  // بناء شريط الإجراءات السفلي مع منطق الحفظ وأيقونة الحفظ المتناسقة
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFFF7A45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // حساب الدرجة التقريبية بناءً على عدد الإجابات المختارة
                  final Map<String, double> newScores = {};
                  if (widget.tool != null && _questions.isNotEmpty) {
                    newScores[widget.tool!.name] =
                        (_selections.length / _questions.length)
                            .clamp(0.1, 1.0);
                  }

                  // استدعاء دالة الحفظ في الـ Provider لتحديث بيانات المقيم في النظام
                  ref.read(appRiverpod).saveSocialAssessment(
                        residentId: widget.resident.id,
                        newScores: newScores,
                        needsIntervention: _isInterventionRequired,
                        notes: _notesController.text,
                      );

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset('assets/animations/Done.json',
                              width: 130, height: 130, repeat: false),
                          const SizedBox(height: 16),
                          const Text(
                            'تم حفظ التقييم بنجاح',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'تم تحديث الملف الاجتماعي والسلوكي للمقيم بنجاح',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext); // Close dialog
                                Navigator.pop(context); // Close screen
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'موافق',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.save_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'حفظ التقييم وإرساله للإدارة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
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
}

// عنصر الـ Chip الخاص بالملاحظات السريعة بتأثيرات وتدرجات حركية رائعة
class _NoteChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _NoteChip(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? null : const Color(0xFFF1F5F9),
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFFF7A45)])
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
