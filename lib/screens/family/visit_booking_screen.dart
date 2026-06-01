import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

class VisitBookingScreen extends ConsumerStatefulWidget {
  const VisitBookingScreen({super.key});

  @override
  ConsumerState<VisitBookingScreen> createState() => _VisitBookingScreenState();
}

class _VisitBookingScreenState extends ConsumerState<VisitBookingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotationController;
  int _selectedType = 0; // 0: Physical, 1: Video
  int _selectedDay = DateTime.now().day;
  String? _selectedSlot;
  final DateTime _now = DateTime.now();
  int _calendarYear = DateTime.now().year;
  int _calendarMonth = DateTime.now().month;

  int get _daysInCurrentCalMonth =>
      DateTime(_calendarYear, _calendarMonth + 1, 0).day;
  String get _monthName => _arabicMonths[_calendarMonth - 1];

  void _prevMonth() {
    setState(() {
      if (_calendarMonth == 1) {
        _calendarMonth = 12;
        _calendarYear--;
      } else {
        _calendarMonth--;
      }
      _selectedDay = 1;
      _selectedSlot = null;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_calendarMonth == 12) {
        _calendarMonth = 1;
        _calendarYear++;
      } else {
        _calendarMonth++;
      }
      _selectedDay = 1;
      _selectedSlot = null;
    });
  }

  final List<String> _arabicMonths = [
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
    'ديسمبر'
  ];

  final List<String> _slots = [
    '٠٩:٠٠ ص',
    '٠٩:٣٠ ص',
    '١٠:٠٠ ص',
    '١٠:٣٠ ص',
    '١١:٠٠ ص',
    '١١:٣٠ ص',
    '١٢:٠٠ م',
    '٠١:٠٠ م',
    '٠٢:٠٠ م',
    '٠٣:٠٠ م',
    '٠٤:٠٠ م',
    '٠٤:٣٠ م',
    '٠٥:٠٠ م',
    '٠٥:٣٠ م',
    '٠٦:٠٠ م',
    '٠٧:٠٠ م',
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: _buildHeader(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionTitle('نوع الزيارة'),
            const SizedBox(height: 16),
            _buildVisitTypeTabs(),
            const SizedBox(height: 32),
            _buildSectionTitle('تحديد التاريخ'),
            const SizedBox(height: 16),
            _buildCalendar(),
            const SizedBox(height: 32),
            _buildSectionTitle('الأوقات المتاحة'),
            const SizedBox(height: 16),
            _buildSlotsGrid(),
            const SizedBox(height: 40),
            _buildConfirmButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFea580c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('جدولة لقاء مودة',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48), // Spacer for balance
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Orb 1 - Top Right
            Positioned(
              top: -50 + (30 * _floatController.value),
              right: -40 + (20 * _floatController.value),
              child: _buildRealisticOrb(180, [
                const Color(0xFFfb923c).withValues(alpha: 0.3),
                const Color(0xFFea580c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            // Orb 2 - Bottom Left
            Positioned(
              bottom: -30 + (40 * (1 - _floatController.value)),
              left: -40 + (25 * _floatController.value),
              child: _buildRealisticOrb(160, [
                const Color(0xFFfdba74).withValues(alpha: 0.25),
                const Color(0xFFf97316).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
            // Orb 3 - Center (Floating)
            Positioned(
              top: 40 + (30 * sin(_floatController.value * pi)),
              left: 100 + (20 * cos(_floatController.value * pi)),
              child: _buildRealisticOrb(80, [
                const Color(0xFFfed7aa).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            // Orb 4 - Near Back Button
            Positioned(
              top: 20,
              left: -10,
              child: _buildRealisticOrb(60, [
                const Color(0xFFfb923c).withValues(alpha: 0.1),
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
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: baseColors,
              ),
            ),
          ),
          RotationTransition(
            turns: _rotationController,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: const Color(0xFFea580c),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b))),
      ],
    );
  }

  Widget _buildVisitTypeTabs() {
    return Row(
      children: [
        Expanded(
            child: _buildTypeCard(0, 'لقاء مودة', Icons.people_alt_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildTypeCard(1, 'مكالمة فيديو', Icons.videocam_rounded)),
      ],
    );
  }

  Widget _buildTypeCard(int index, String label, IconData icon) {
    bool isSel = _selectedType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFfff7ed) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSel ? const Color(0xFFea580c) : const Color(0xFFf1f5f9),
              width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isSel ? 0.05 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    isSel ? const Color(0xFFea580c) : const Color(0xFF94a3b8),
                size: 32),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: isSel
                        ? const Color(0xFFea580c)
                        : const Color(0xFF64748b),
                    fontSize: 16,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF94a3b8)),
                onPressed: () {
                  final isCurrentMonth = _calendarYear == _now.year &&
                      _calendarMonth == _now.month;
                  if (!isCurrentMonth) _prevMonth();
                },
              ),
              Text('$_monthName $_calendarYear',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF94a3b8)),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1),
            itemCount: _daysInCurrentCalMonth,
            itemBuilder: (context, i) {
              int day = i + 1;
              bool isSelected = day == _selectedDay;
              final isSameMonth =
                  _calendarYear == _now.year && _calendarMonth == _now.month;
              bool isPast = isSameMonth && day < _now.day;
              return GestureDetector(
                onTap: isPast ? null : () => setState(() => _selectedDay = day),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFea580c)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isPast
                                ? const Color(0xFFcbd5e1)
                                : const Color(0xFF475569)),
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: _slots.map((slot) {
        bool isSel = _selectedSlot == slot;
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: Container(
            width: (MediaQuery.of(context).size.width - 64) / 3,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFFea580c) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSel ? Colors.transparent : const Color(0xFFf1f5f9),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: isSel ? 0.1 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Center(
              child: Text(
                slot,
                style: TextStyle(
                    color: isSel ? Colors.white : const Color(0xFF64748b),
                    fontSize: 14,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton() {
    bool canConfirm = _selectedSlot != null;
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: canConfirm
            ? const LinearGradient(
                colors: [Color(0xFFea580c), Color(0xFFf97316)])
            : null,
        color: canConfirm ? null : const Color(0xFFe2e8f0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: canConfirm
            ? [
                BoxShadow(
                    color: const Color(0xFFea580c).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        onPressed: canConfirm
            ? () async {
                final provider = ref.read(appRiverpod);
                await provider.addFamilyVisit(FamilyVisit(
                  id: 'v${DateTime.now().millisecondsSinceEpoch}',
                  visitorName: provider.currentAccount?.name ?? 'فرد أسرة',
                  date: '$_selectedDay $_monthName $_calendarYear',
                  time: _selectedSlot!,
                  type: _selectedType == 0 ? 'physical' : 'video',
                  status: 'pending',
                  scheduledAt:
                      DateTime(_calendarYear, _calendarMonth, _selectedDay),
                ));
                if (!mounted) return;
                if (provider.backendSyncError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.backendSyncError!),
                      backgroundColor: const Color(0xFFef4444),
                    ),
                  );
                } else {
                  _showSuccessSheet();
                }
              }
            : null,
        child: const Text('تأكيد الموعد',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFFf0fdf4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFdcfce7), width: 4)),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF22c55e), size: 50),
            ),
            const SizedBox(height: 24),
            const Text('تم تأكيد الموعد بنجاح!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'تم إرسال تفاصيل الزيارة إلى هاتفك وإلى إدارة المركز. نحن بانتظارك! ✨',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748b), fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFea580c),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pop(context); // back to dashboard
                },
                child: const Text('رجوع للرئيسية',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
