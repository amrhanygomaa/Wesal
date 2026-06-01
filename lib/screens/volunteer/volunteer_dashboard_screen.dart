import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import 'opportunities_view.dart';
import 'bookings_view.dart';
import 'certificates_view.dart';
import 'ratings_view.dart';
import 'profile_view.dart';
import '../../widgets/taptaba_scaffold.dart';

class VolunteerDashboardScreen extends ConsumerStatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  ConsumerState<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState
    extends ConsumerState<VolunteerDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;
  late AnimationController _ringController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _popController;
  AnimationController? _rotationController;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimations = List.generate(
      12,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.08, 1.0, curve: Curves.easeOut),
        ),
      ),
    );

    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _popController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _fadeController.forward();
    _ringController.forward();
    _popController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ringController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _rotationController?.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return TaptabaScaffold(
      title: 'ونس',
      titleColor: const Color(0xFF059669),
      overrideRole: 'متطوع',
      transparentAppBar: true,
      extendBodyBehindAppBar: true,
      hideAppBarOnScroll: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(provider),
                  _buildCurrentView(provider),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildCurrentView(AppRiverpod provider) {
    switch (_selectedTab) {
      case 1:
        return VolunteerOpportunitiesView(
          fadeAnimations: _fadeAnimations,
          floatController: _floatController,
          shimmerController: _shimmerController,
        );
      case 2:
        return VolunteerBookingsView(
          fadeAnimations: _fadeAnimations,
          floatController: _floatController,
          shimmerController: _shimmerController,
          popController: _popController,
        );
      case 3:
        return VolunteerCertificatesView(
          fadeAnimations: _fadeAnimations,
          floatController: _floatController,
          shimmerController: _shimmerController,
          popController: _popController,
        );
      case 4:
        return VolunteerRatingsView(
          fadeAnimations: _fadeAnimations,
          floatController: _floatController,
          shimmerController: _shimmerController,
          popController: _popController,
        );
      case 0:
      default:
        return VolunteerProfileView(
          fadeAnimations: _fadeAnimations,
          floatController: _floatController,
          shimmerController: _shimmerController,
          popController: _popController,
          onSeeAllOpportunities: () => setState(() => _selectedTab = 1),
        );
    }
  }

  Widget _buildHero(AppRiverpod provider) {
    final isCertTab = _selectedTab == 3;
    final isRatingTab = _selectedTab == 4;
    final opportunitiesCount = provider.volunteerOpportunities.length;
    final todayStart = _dateOnly(DateTime.now());
    final upcomingBookingsCount = provider.volunteerBookings
        .where((booking) =>
            booking.status == 'confirmed' &&
            !booking.startTime.isBefore(todayStart))
        .length;
    final bookingsSummary = '$upcomingBookingsCount حجوزات مقبلة';
    final certsCount =
        '${provider.volunteerCertificates.where((c) => !c.isLocked).length}';
    final ratingSummary = provider.averageRating > 0
        ? '⭐ ${provider.averageRating.toStringAsFixed(1)}'
        : '⭐ —';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRatingTab
              ? [
                  const Color(0xFF064e3b),
                  const Color(0xFF059669),
                  const Color(0xFF10b981)
                ]
              : (isCertTab
                  ? [
                      const Color(0xFF065f46),
                      const Color(0xFF059669),
                      const Color(0xFF10b981)
                    ]
                  : [
                      const Color(0xFF064e3b),
                      const Color(0xFF059669),
                      const Color(0xFF10b981)
                    ]),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _buildAnimatedBackground()),
          const VolunteerDustAnimation(), // إضافة تأثير الجزيئات المتطايرة
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, isRatingTab ? 32 : 40, 24, isRatingTab ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _selectedTab == 1
                                  ? '🎯 فرص التطوع'
                                  : (_selectedTab == 2
                                      ? '📅 حجوزاتي'
                                      : (isCertTab
                                          ? '🏅 شهاداتي'
                                          : (isRatingTab
                                              ? '⭐ تقييمي'
                                              : 'أهلاً بك يا'))),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(
                              _selectedTab == 1
                                  ? '$opportunitiesCount فرص متاحة دلوقتي'
                                  : (_selectedTab == 2
                                      ? bookingsSummary
                                      : (isCertTab
                                          ? '$certsCount شهادات مكتسبة'
                                          : (isRatingTab
                                              ? ratingSummary
                                              : provider.currentUser.name))),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isCertTab)
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('مشاركة سجل الشهادات والإنجازات... 🏆'),
                              backgroundColor: Color(0xFF059669),
                            ));
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_outlined,
                              color: Colors.white),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
                if (_selectedTab == 0) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroChip('${provider.volunteerGoal} ساعة',
                                'الهدف الشهري'),
                            const SizedBox(height: 8),
                            _buildHeroChip(
                                '⭐ ${provider.volunteerBookings.where((b) => b.status == 'done').length} جلسة',
                                'جلسات مكتملة'),
                            const SizedBox(height: 8),
                            _buildHeroChip('⭐⭐⭐⭐⭐', 'تقييم المقيمين'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(100, 100),
                                  painter: RingPainter(
                                    progress: _ringController.value *
                                        (provider.volunteerHours /
                                            provider.volunteerGoal),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    progressColor: Colors.white,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${provider.volunteerHours}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    const Text('ساعة',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ] else if (_selectedTab == 1) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTopChip(
                          'مناسب لمهاراتك ${provider.volunteerOpportunities.where((o) => o.tags.any((t) => provider.volunteerProfile.skills.contains(t))).length}',
                          const Color(0xFF4ade80)),
                      _buildTopChip('هذا الأسبوع ٣', const Color(0xFFfbbf24)),
                      _buildTopChip('محجوزة ٢', const Color(0xFF60a5fa)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () =>
                        _showMatchingOpportunitiesDetails(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${provider.volunteerOpportunities.where((o) => o.tags.any((t) => provider.volunteerProfile.skills.contains(t))).length} فرص',
                                style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'مطابق لمهاراتك: ${provider.volunteerProfile.skills.take(3).join('، ')}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right),
                          ),
                          const SizedBox(width: 8),
                          const Text('🎯', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ] else if (_selectedTab == 2) ...[
                  const SizedBox(height: 16),
                  _buildCalendarStrip(provider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _toArabicDigits(int value) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value
        .toString()
        .split('')
        .map((char) =>
            int.tryParse(char) == null ? char : digits[int.parse(char)])
        .join();
  }

  String _weekdayLabel(DateTime date) {
    const labels = {
      DateTime.saturday: 'سبت',
      DateTime.sunday: 'أحد',
      DateTime.monday: 'إث',
      DateTime.tuesday: 'ثلا',
      DateTime.wednesday: 'أربع',
      DateTime.thursday: 'خمس',
      DateTime.friday: 'جمع',
    };
    return labels[date.weekday] ?? '';
  }

  bool _hasBookingOnDate(AppRiverpod provider, DateTime date) {
    return provider.volunteerBookings.any((booking) {
      return booking.status == 'confirmed' &&
          _isSameCalendarDay(booking.startTime, date);
    });
  }

  Widget _buildCalendarStrip(AppRiverpod provider) {
    final today = _dateOnly(DateTime.now());
    final days = List<DateTime>.generate(
      6,
      (index) => DateTime(today.year, today.month, today.day + index - 2),
    );

    return SizedBox(
      height: 60,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((date) {
          final isActive = _isSameCalendarDay(date, today);
          final hasDot = _hasBookingOnDate(provider, date);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weekdayLabel(date),
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFF064e3b)
                              : Colors.white.withValues(alpha: 0.75),
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                  Text(_toArabicDigits(date.day),
                      style: TextStyle(
                          color:
                              isActive ? const Color(0xFF064e3b) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  if (hasDot)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFfbbf24),
                          shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopChip(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildHeroChip(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 11)),
          const SizedBox(width: 12),
          Text(val,
              textAlign: TextAlign.left,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildNavTabs() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(0, '🏠', 'ملفي'),
          _buildTabItem(1, '🎯', 'الفرص'),
          _buildTabItem(2, '📅', 'حجوزاتي'),
          _buildTabItem(3, '🏅', 'شهاداتي'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String icon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF10b981) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF059669)
                      : const Color(0xFF94a3b8),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.person_outline, 'ملفي'),
          _buildNavItem(1, Icons.track_changes, 'الفرص'),
          _buildNavItem(2, Icons.calendar_month_outlined, 'حجوزاتي'),
          _buildNavItem(3, Icons.card_membership_outlined, 'شهاداتي'),
          _buildNavItem(4, Icons.star_border, 'تقييمي'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: active ? const Color(0xFF059669) : const Color(0xFF94a3b8),
              size: 24),
          Text(label,
              style: TextStyle(
                  color: active
                      ? const Color(0xFF059669)
                      : const Color(0xFF64748b),
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500)),
          if (active)
            Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: Color(0xFF10b981), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  void _showMatchingOpportunitiesDetails(
      BuildContext context, AppRiverpod provider) {
    final matchingOpps = provider.volunteerOpportunities
        .where((o) =>
            o.tags.any((t) => provider.volunteerProfile.skills.contains(t)))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFf8fafc),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFdcfce7),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('🎯', style: TextStyle(fontSize: 20)),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('فرص تطوعية لمهاراتك',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF064e3b))),
                      Text('بناءً على اهتماماتك وخبراتك السابقة',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF64748b))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: matchingOpps.length,
                itemBuilder: (context, index) {
                  final opp = matchingOpps[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(opp.icon,
                                style: const TextStyle(fontSize: 24)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFf0fdf4),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('${opp.points} نقطة',
                                  style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(opp.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1e293b))),
                        Text(opp.org,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748b))),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: opp.tags
                              .map((t) => Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFf1f5f9),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(t,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF475569))),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('تم حجز "${opp.title}" بنجاح! 🎉'),
                              backgroundColor: const Color(0xFF059669),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('احجز الآن',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Color(0xFFe2e8f0)),
                ),
                child: const Text('إغلاق',
                    style: TextStyle(
                        color: Color(0xFF64748b), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    if (_rotationController == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController!]),
      builder: (context, child) {
        return Stack(
          children: [
            // Major Orb - Top Right
            Positioned(
              top: -40 + (30 * _floatController.value),
              right: -50 + (20 * _floatController.value),
              child: _buildRealisticOrb(180, [
                const Color(0xFFC7D2FE).withValues(alpha: 0.1),
                const Color(0xFF818CF8).withValues(alpha: 0.05),
                const Color(0xFF10b981).withValues(alpha: 0.02),
              ]),
            ),
            // Middle Orb - Bottom Left
            Positioned(
              bottom: -20 + (40 * (1 - _floatController.value)),
              left: -30 + (15 * _floatController.value),
              child: _buildRealisticOrb(140, [
                const Color(0xFF6EE7B7).withValues(alpha: 0.08),
                const Color(0xFF10B981).withValues(alpha: 0.04),
                const Color(0xFF064E3B).withValues(alpha: 0.01),
              ]),
            ),
            // Small Floating Orb - Center Left
            Positioned(
              top: 100 + (30 * sin(_floatController.value * pi)),
              left: 40 + (40 * cos(_floatController.value * pi)),
              child: _buildRealisticOrb(90, [
                const Color(0xFFFDE68A).withValues(alpha: 0.05),
                const Color(0xFFF59E0B).withValues(alpha: 0.02),
                const Color(0xFF78350F).withValues(alpha: 0.01),
              ]),
            ),
            // Extra Orb - Center Right
            Positioned(
              top: 40 + (20 * _floatController.value),
              right: 80 - (10 * _floatController.value),
              child: _buildRealisticOrb(70, [
                const Color(0xFF10b981).withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.02),
                Colors.transparent,
              ]),
            ),
            // Extra Orb - Bottom Right
            Positioned(
              bottom: 10,
              right: 40 + (20 * _floatController.value),
              child: _buildRealisticOrb(110, [
                const Color(0xFF10B981).withValues(alpha: 0.03),
                const Color(0xFF064E3B).withValues(alpha: 0.01),
                Colors.transparent,
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealisticOrb(double size, List<Color> baseColors) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: Stack(
          children: [
            // Base Marble Gradient
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: baseColors,
                  stops: const [0.0, 0.5, 1.0],
                  radius: 1.0,
                ),
              ),
            ),
            // Rotating Swirls
            if (_rotationController != null)
              RotationTransition(
                turns: _rotationController!,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            // Glassy Reflection Top Left
            Positioned(
              top: size * 0.1,
              left: size * 0.15,
              child: Container(
                width: size * 0.4,
                height: size * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  RingPainter(
      {required this.progress,
      required this.backgroundColor,
      required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 4;
    const strokeWidth = 8.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- تأثير الجزيئات المتطايرة الجديد ---

class VolunteerDustParticle {
  Offset position;
  double speed;
  double radius;
  Color color;

  VolunteerDustParticle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.color,
  });
}

class VolunteerDustAnimation extends StatefulWidget {
  const VolunteerDustAnimation({super.key});

  @override
  State<VolunteerDustAnimation> createState() => _VolunteerDustAnimationState();
}

class _VolunteerDustAnimationState extends State<VolunteerDustAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<VolunteerDustParticle> _dust;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    final random = Random();
    final colors = [
      const Color(0xFF4ade80).withValues(alpha: 0.6), // أخضر فاتح
      const Color(0xFFfacc15).withValues(alpha: 0.6), // أصفر ذهبي
    ];

    _dust = List.generate(200, (index) {
      // كثرناها لـ 200 بناء على طلب المستخدم
      return VolunteerDustParticle(
        position: Offset(random.nextDouble(), random.nextDouble()),
        speed: random.nextDouble() * 0.04 + 0.01,
        radius: random.nextDouble() * 2.0 + 0.5,
        color: colors[random.nextInt(colors.length)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: VolunteerDustPainter(
                dust: _dust, animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class VolunteerDustPainter extends CustomPainter {
  final List<VolunteerDustParticle> dust;
  final double animationValue;

  VolunteerDustPainter({required this.dust, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < dust.length; i++) {
      final p = dust[i];

      double dy = (p.position.dy * size.height) -
          (animationValue * p.speed * size.height);
      if (dy < 0) dy += size.height;

      double dx =
          p.position.dx * size.width + sin(animationValue * 2 * pi + i) * 5;

      final currentPos = Offset(dx, dy);

      double opacity = (sin(animationValue * 2 * pi * 2 + i) + 1) / 2;
      paint.color = p.color.withValues(alpha: p.color.a * opacity);

      canvas.drawCircle(currentPos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VolunteerDustPainter oldDelegate) {
    return true;
  }
}
