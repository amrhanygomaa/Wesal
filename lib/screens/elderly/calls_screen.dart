import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../chat/family_resident_chat_screen.dart';
import 'heart_messages_screen.dart';

class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _rippleController;
  late AnimationController _ringController;
  late AnimationController _waveController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  bool _showAllFamily = false; // التحكم في عرض المزيد من الأرقام المفضلة

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _rippleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appRiverpod).loadFamilyCardPreferences();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _rippleController.dispose();
    _ringController.dispose();
    _waveController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    return Stack(
      children: [
        SingleChildScrollView(
          padding:
              const EdgeInsets.only(bottom: 120), // العودة للمساحة الطبيعية
          child: Column(
            children: [
              _buildHero(provider),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (provider.isIncomingCall) _buildIncomingCall(provider),
                    if (provider.isIncomingCall) const SizedBox(height: 12),
                    _buildFamilyGrid(provider),
                    const SizedBox(height: 12),
                    _buildVoiceMessages(provider),
                    const SizedBox(height: 12),
                    _buildRecentCalls(provider),
                  ],
                ),
              ),
            ],
          ),
        ),
        // تم حذف الزر العائم من هنا لدمجه في الصندوق الخاص به بالأسفل
      ],
    );
  }

  // ignore: unused_element
  Widget _buildRecordingButton(AppRiverpod provider) {
    return Center(
      child: GestureDetector(
        onTap: () => _showRecordDialog(provider),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFc084fc)],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('اضغط لتسجيل رسالة للأسرة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDialog(AppRiverpod provider) {
    _openHeartMessagesPage(autoRecord: true);
  }

  void _openHeartMessagesPage({bool autoRecord = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HeartMessagesScreen(autoRecord: autoRecord),
      ),
    );
  }

  Widget _buildHero(AppRiverpod provider) {
    int availableCount =
        provider.familyMembers.where((m) => m.isAvailable).length;
    int busyCount = provider.familyMembers.length - availableCount;
    int voiceMsgCount = provider.voiceMessages.length;
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a0533),
                Color(0xFF3730a3),
                Color(0xFF0f3460),
                Color(0xFF6C63FF)
              ],
            ),
          ),
          child: Stack(
            children: [
              _buildBlob(180, const Color(0xFF6C63FF), -50, -50, 7),
              _buildBlob(130, const Color(0xFFf472b6), -35, 30, 9),
              _buildBlob(80, const Color(0xFF0ea5e9), 80, -10, 6),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 28, top: 4, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الأسرة والتواصل',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$availableCount متاحين الآن',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 12, bottom: 24),
                      child: Row(
                        children: [
                          _buildHeroChip('● $availableCount', 'متاح', 0,
                              const Color(0xFF4ade80), provider),
                          const SizedBox(width: 8),
                          _buildHeroChip('● $busyCount', 'مشغول', 1,
                              Colors.white, provider),
                          const SizedBox(width: 8),
                          _buildHeroChip('$voiceMsgCount', 'رسائل', 2,
                              Colors.white, provider),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlob(
      double size, Color color, double right, double top, double duration) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value * 2 * pi;
        final x = sin(t * (duration / 7)) * 10;
        final y = cos(t * (duration / 7)) * 12;
        return Positioned(
          left: right + x,
          top: top + y,
          child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withValues(alpha: 0.4))),
        );
      },
    );
  }

  Widget _buildHeroChip(String value, String label, int index, Color valueColor,
      AppRiverpod provider) {
    bool hc = provider.isHighContrast;
    Color chipColor;
    Color borderColor;

    switch (index) {
      case 0: // متاح
        chipColor =
            const Color(0xFF10B981).withValues(alpha: 0.15); // أخضر خفيف
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.3);
        break;
      case 1: // مشغول
        chipColor =
            const Color(0xFF8B5CF6).withValues(alpha: 0.15); // بنفسجي فاتح
        borderColor = const Color(0xFF8B5CF6).withValues(alpha: 0.3);
        break;
      case 2: // رسائل
        chipColor = const Color(0xFF3B82F6).withValues(alpha: 0.15); // أزرق
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        break;
      default:
        chipColor = Colors.white.withValues(alpha: hc ? 0.08 : 0.13);
        borderColor = Colors.white.withValues(alpha: hc ? 0.05 : 0.1);
    }

    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.6, end: 1),
        duration: Duration(milliseconds: 450 + (index * 120)),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildIncomingCall(AppRiverpod provider) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF059669),
                  Color(0xFF10b981),
                  Color(0xFF34d399)
                ]),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF10b981).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 6))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1)))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _rippleController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1 + (_rippleController.value * 1.4),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white.withValues(
                                                    alpha: 0.5 *
                                                        (1 -
                                                            _rippleController
                                                                .value)),
                                                width: 2)),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _floatController,
                                  builder: (context, child) =>
                                      Transform.translate(
                                          offset: Offset(
                                              0, -4 * _floatController.value),
                                          child: child),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white
                                            .withValues(alpha: 0.25)),
                                    child: const Center(
                                        child: Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('سا',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedBuilder(
                                  animation: _ringController,
                                  builder: (context, child) {
                                    final shake = sin(
                                            _ringController.value * pi * 4) *
                                        (sin(_ringController.value * pi * 2) >
                                                0.5
                                            ? 14
                                            : -14);
                                    return Transform.rotate(
                                        angle: shake * pi / 180, child: child);
                                  },
                                  child: const Text('📲 بتتصل بك الآن...',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                      provider.activeCallerName.isEmpty
                                          ? 'مكالمة واردة'
                                          : provider.activeCallerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 4),
                                const Flexible(
                                  child: Text('مكالمة فيديو واردة',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => provider.acceptCall(),
                                child: AnimatedBuilder(
                                  animation: _glowController,
                                  builder: (context, child) => Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                              color: const Color(0xFF4ade80)
                                                  .withValues(
                                                      alpha: 0.5 +
                                                          (_glowController
                                                                  .value *
                                                              0.5)),
                                              blurRadius: 10 +
                                                  (_glowController.value * 10),
                                              spreadRadius:
                                                  _glowController.value * 5)
                                        ]),
                                    child: const Icon(Icons.check,
                                        color: Color(0xFF059669), size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => provider.rejectCall(),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.25)),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildWaveBar(4, 0),
                          const SizedBox(width: 3),
                          _buildWaveBar(9, 1),
                          const SizedBox(width: 3),
                          _buildWaveBar(14, 2),
                          const SizedBox(width: 3),
                          _buildWaveBar(9, 3),
                          const SizedBox(width: 3),
                          _buildWaveBar(4, 4),
                          const SizedBox(width: 8),
                          const Text('مكالمة واردة',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveBar(double height, int index) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final delay = index * 0.1;
        final t = (_waveController.value + delay) % 1;
        final scale = 1 + (sin(t * pi * 2) * 0.8);
        return Transform.scale(
          scaleY: scale,
          child: Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2))),
        );
      },
    );
  }

  Widget _buildFamilyGrid(AppRiverpod provider) {
    bool hc = provider.isHighContrast;
    return LayoutBuilder(
      builder: (context, constraints) {
        final favoriteMembers =
            provider.favoriteFamilyMembersForCurrentResident(
          ignoreLimit: true,
        );
        final displayLimit =
            provider.familyCardDisplayLimitForCurrentResident();
        final displayMembers = _showAllFamily
            ? favoriteMembers
            : favoriteMembers.take(displayLimit).toList();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: hc ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: hc ? const Color(0xFF333333) : const Color(0xFFede9fe),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF6C63FF)
                        .withValues(alpha: hc ? 0.2 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ]),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // لجعل الصندوق مرناً
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people_alt_rounded,
                                color: Color(0xFF6C63FF), size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text('تواصل مع أحبائك 💜',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF6C63FF))),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showManageContactsSheet(provider),
                      icon: const Icon(Icons.settings_suggest_rounded,
                          color: Color(0xFF6C63FF)),
                      tooltip: 'إدارة الأرقام',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (provider.familyMembersForCurrentResident().isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                          'لا يوجد أفراد عائلة مرتبطون بهذا المقيم حالياً.\nيمكن للأدمن إضافتهم من ملف المقيم.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF94a3b8), fontSize: 16)),
                    ),
                  )
                else if (favoriteMembers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                          'لم يتم اختيار أشخاص مفضلين بعد.\nاضغط على الإعدادات واختر من يظهر هنا.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF94a3b8), fontSize: 16)),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < displayMembers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPersonCard(
                            displayMembers[i],
                            [
                              const [Color(0xFFf472b6), Color(0xFFdb2777)],
                              const [Color(0xFF34d399), Color(0xFF059669)],
                              const [Color(0xFF818cf8), Color(0xFF4f46e5)],
                              const [Color(0xFFfbbf24), Color(0xFFd97706)]
                            ][i % 4],
                            i,
                            provider,
                          ),
                        ),
                      if (favoriteMembers.length > displayLimit)
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _showAllFamily = !_showAllFamily),
                          icon: Icon(_showAllFamily
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded),
                          label: Text(
                              _showAllFamily ? 'عرض أقل' : 'عرض المزيد ➕',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManageContactsSheet(AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text('اختر الأشخاص الذين يظهرون في كارت التواصل',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                  'القائمة مرتبطة بأفراد العائلة الموجودين في ملف المقيم',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'عدد الأشخاص في الكارت',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  max(
                      1,
                      min(6,
                          provider.familyMembersForCurrentResident().length)),
                  (index) {
                    final value = index + 1;
                    final selected = value ==
                        provider.familyCardDisplayLimitForCurrentResident();
                    return ChoiceChip(
                      label: Text('$value'),
                      selected: selected,
                      selectedColor: const Color(0xFF6C63FF),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) async {
                        await provider.setFamilyCardDisplayLimit(value);
                        setModalState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.familyMembersForCurrentResident().length,
                  itemBuilder: (context, index) {
                    final members = provider.familyMembersForCurrentResident();
                    final member = members[index];
                    return CheckboxListTile(
                      title: Text(member.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text(member.relation,
                          style: const TextStyle(color: Colors.grey)),
                      value: provider.isFamilyCardFavorite(member.id),
                      activeColor: const Color(0xFF6C63FF),
                      onChanged: (val) async {
                        await provider.setFamilyCardFavorite(
                          member.id,
                          val == true,
                        );
                        setModalState(() {});
                      },
                      secondary: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        child: Text(member.initials,
                            style: const TextStyle(color: Color(0xFF6C63FF))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('حفظ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(FamilyMember member, List<Color> gradient, int delay,
      AppRiverpod provider) {
    final bool isOnline = member.isAvailable;
    final bool hasApp = member.userId != null && member.userId!.isNotEmpty;
    final bool hc = provider.isHighContrast;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hc ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOnline
                ? const Color(0xFF6C63FF).withValues(alpha: 0.25)
                : (hc ? const Color(0xFF333333) : const Color(0xFFF0F0F5)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOnline
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: avatar + name/relation ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isOnline
                              ? gradient
                              : [
                                  const Color(0xFFE5E7EB),
                                  const Color(0xFFD1D5DB)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline
                                    ? gradient[0]
                                    : const Color(0xFF9CA3AF))
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ade80),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  hc ? const Color(0xFF252525) : Colors.white,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name + relation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: hc ? Colors.white : const Color(0xFF1a1a1a),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isOnline
                                  ? const Color(0xFF6C63FF)
                                  : const Color(0xFF9CA3AF))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          member.relation,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isOnline
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // ── Bottom row: action buttons evenly spaced ─────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Video call
                _buildActionCircle(
                  onTap: () {
                    if (!hasApp) {
                      _showNotOnAppFeedback(member.name);
                      return;
                    }
                    provider.startVideoCall(
                      member.name,
                      member.initials,
                      calleeId: member.userId,
                      residentId: provider.backendResidentId,
                    );
                  },
                  icon: Icons.videocam_rounded,
                  color: const Color(0xFF6C63FF),
                  isActive: hasApp,
                  hc: hc,
                  tooltip: hasApp ? 'مكالمة فيديو' : 'ليس على التطبيق',
                ),
                // Phone call
                _buildActionCircle(
                  onTap: () => provider.callPhoneNumber(member.phoneNumber),
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF4ade80),
                  isActive: member.phoneNumber.isNotEmpty,
                  hc: hc,
                  isOutlined: true,
                  tooltip: 'اتصال هاتفي',
                ),
                // Chat
                _buildActionCircle(
                  onTap: hasApp
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FamilyResidentChatScreen(
                                otherUserId: member.userId!,
                                otherUserName: member.name,
                                otherUserRole: member.relation,
                                residentId: provider.backendResidentId,
                                accentColor: const Color(0xFF6C63FF),
                              ),
                            ),
                          )
                      : () => _showNotOnAppFeedback(member.name),
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFFea580c),
                  isActive: hasApp,
                  hc: hc,
                  isOutlined: true,
                  tooltip: hasApp ? 'رسالة' : 'ليس على التطبيق',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNotOnAppFeedback(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$name ليس مستخدماً على تطبيق ونس حتى الآن',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF374151),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildActionCircle({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool hc,
    bool isOutlined = false,
    String tooltip = '',
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOutlined
                ? (isActive
                    ? color.withValues(alpha: 0.12)
                    : (hc ? Colors.white10 : const Color(0xFFF3F4F6)))
                : (isActive
                    ? color
                    : (hc
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFE5E7EB))),
            shape: BoxShape.circle,
            border: isOutlined && isActive
                ? Border.all(color: color.withValues(alpha: 0.45), width: 1.5)
                : null,
            boxShadow: !isOutlined && isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isOutlined
                ? (isActive
                    ? color
                    : (hc ? Colors.white38 : const Color(0xFFB0B7C3)))
                : (isActive
                    ? Colors.white
                    : (hc ? Colors.white38 : const Color(0xFFB0B7C3))),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceMessages(AppRiverpod provider) {
    final received =
        provider.voiceMessages.where((m) => m.senderId != 'resident').toList();
    final sent =
        provider.voiceMessages.where((m) => m.senderId == 'resident').toList();

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFede9fe), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _openHeartMessagesPage,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF6C63FF), size: 24),
                  Spacer(),
                  Text('رسائل من القلب ✨',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF))),
                  SizedBox(width: 8),
                  Icon(Icons.mic_rounded, color: Color(0xFF6C63FF), size: 24),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => _showRecordDialog(provider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFa78bfa)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text('سجّل رسالة لعائلتك',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (sent.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.send_rounded, color: Color(0xFF10b981), size: 18),
                  SizedBox(width: 6),
                  Text('رسائلي المُرسلة',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10b981))),
                ],
              ),
              const SizedBox(height: 8),
              ...sent.asMap().entries.map((e) => Column(
                    children: [
                      if (e.key > 0)
                        const Divider(color: Color(0xFFf0fdf4), thickness: 1),
                      _buildSentVoiceRow(e.value),
                    ],
                  )),
            ],
            if (received.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFf5f3ff), thickness: 1),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.inbox_rounded, color: Color(0xFF6C63FF), size: 18),
                  SizedBox(width: 6),
                  Text('رسائل من العائلة',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF))),
                ],
              ),
              const SizedBox(height: 8),
              ...received.asMap().entries.map((entry) {
                final index = entry.key;
                final msg = entry.value;
                final sender = provider.familyMembers
                    .firstWhere((m) => m.id == msg.senderId,
                        orElse: () => provider.familyMembers.isNotEmpty
                            ? provider.familyMembers.first
                            : FamilyMember(
                                id: msg.senderId,
                                name: 'أحد أفراد العائلة',
                                relation: 'قريب',
                                avatarPath: '',
                                initials: '؟',
                                phoneNumber: '',
                              ));
                final gradients = [
                  const [Color(0xFFf472b6), Color(0xFFdb2777)],
                  const [Color(0xFF34d399), Color(0xFF059669)],
                  const [Color(0xFF818cf8), Color(0xFF4f46e5)],
                  const [Color(0xFFfbbf24), Color(0xFFd97706)],
                ];
                final pGradient = gradients[index % gradients.length];
                return Column(
                  children: [
                    if (index > 0) const Divider(color: Color(0xFFf5f3ff)),
                    _buildVoiceMessageRow(provider, msg, sender, pGradient),
                  ],
                );
              }),
            ],
            if (received.isEmpty && sent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'لا توجد رسائل بعد\nسجّل رسالتك الأولى لعائلتك!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF94a3b8), height: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentVoiceRow(VoiceMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10b981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b)),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.timeDescription,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFdcfce7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10b981), size: 16),
                SizedBox(width: 4),
                Text('تم الإرسال',
                    style: TextStyle(
                        color: Color(0xFF10b981),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessageRow(AppRiverpod provider, VoiceMessage msg,
      FamilyMember sender, List<Color> gradient) {
    bool isPlaying = msg.isPlaying;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]),
            child: Center(
                child: Text(sender.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
                const SizedBox(height: 2),
                Text(msg.timeDescription,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF64748b))),
              ],
            ),
          ),
          if (isPlaying)
            Row(
              children: [
                _buildVoiceWave(4, 0, const Color(0xFFc4b5fd)),
                const SizedBox(width: 2),
                _buildVoiceWave(9, 1, const Color(0xFFa78bfa)),
                const SizedBox(width: 2),
                _buildVoiceWave(4, 2, const Color(0xFFc4b5fd)),
              ],
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => provider.toggleVoiceMessage(msg.id),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFf3e8ff),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFe9d5ff)),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFFa855f7),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWave(double height, int index, Color color) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final delay = index * 0.133;
        final t = (_waveController.value + delay) % 1;
        final scale = 1 + (sin(t * pi * 2) * 0.8);
        return Transform.scale(
          scaleY: scale,
          child: Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
        );
      },
    );
  }

  Widget _buildRecentCalls(AppRiverpod provider) {
    final calls = provider.callHistory.take(3).toList();
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFede9fe), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.assignment_rounded,
                    color: Color(0xFF6C63FF), size: 24),
                SizedBox(width: 8),
                Text('آخر المكالمات',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF))),
              ],
            ),
            const SizedBox(height: 10),
            if (calls.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('لا توجد مكالمات من السيرفر حتى الآن',
                    style: TextStyle(color: Color(0xFF64748b))),
              )
            else
              for (final call in calls) ...[
                _buildRecentCallRow(
                    call.calleeName?.isNotEmpty == true
                        ? call.calleeName!
                        : 'مكالمة',
                    '${call.callType} · ${call.startedAt}',
                    call.calleeName?.isNotEmpty == true
                        ? call.calleeName!.substring(0, 1)
                        : 'م',
                    const [Color(0xFF818cf8), Color(0xFF4f46e5)],
                    call.status,
                    const Color(0xFFede9fe),
                    const Color(0xFF4c1d95)),
                const Divider(color: Color(0xFFf5f3ff)),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCallRow(String name, String detail, String initials,
      List<Color> gradient, String badge, Color badgeBg, Color badgeText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // Right: Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]),
            child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          // Middle: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
                const SizedBox(height: 2),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748b))),
              ],
            ),
          ),
          // Left: Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: badgeBg.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10)),
            child: Text(badge,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: badgeText)),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color primaryColor,
    required bool isActive,
    required bool hc,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: (!isOutlined && isActive)
              ? LinearGradient(
                  colors: [primaryColor, primaryColor.withBlue(255)],
                )
              : null,
          color: isOutlined
              ? (isActive
                  ? primaryColor.withValues(alpha: 0.08)
                  : (hc ? Colors.white10 : const Color(0xFFF3F4F6)))
              : (isActive
                  ? null
                  : (hc
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFE5E7EB))),
          borderRadius: BorderRadius.circular(14),
          border: isOutlined && isActive
              ? Border.all(
                  color: primaryColor.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined
                  ? (isActive
                      ? primaryColor
                      : (hc ? Colors.white38 : const Color(0xFF9CA3AF)))
                  : (isActive
                      ? Colors.white
                      : (hc ? Colors.white38 : const Color(0xFF9CA3AF))),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isOutlined
                    ? (isActive
                        ? primaryColor
                        : (hc ? Colors.white38 : const Color(0xFF9CA3AF)))
                    : (isActive
                        ? Colors.white
                        : (hc ? Colors.white38 : const Color(0xFF9CA3AF))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordDialog extends StatefulWidget {
  final AppRiverpod provider;
  final BuildContext parentContext;

  const _RecordDialog({required this.provider, required this.parentContext});

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _titleCtrl = TextEditingController(text: 'رسالة من القلب');
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isSending = false;
  String? _recordedPath;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _timer?.cancel();
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } else {
      final messenger = ScaffoldMessenger.of(widget.parentContext);
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('يرجى السماح للتطبيق بالوصول للميكروفون'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _seconds = 0;
        _recordedPath = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    }
  }

  Future<void> _send() async {
    if (_recordedPath == null) return;
    setState(() => _isSending = true);
    final title =
        _titleCtrl.text.trim().isEmpty ? 'رسالة صوتية' : _titleCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    await widget.provider.sendVoiceMessageFromResident(
      title,
      audioPath: _recordedPath,
      durationSeconds: _seconds,
    );
    if (mounted) {
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رسالتك الصوتية للأسرة 🎤❤️'),
          backgroundColor: Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'رسالة من القلب ✨',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              enabled: !_isRecording && !_isSending,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'اسم الرسالة',
                hintText: 'مثال: رسالة الصباح',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF6C63FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isRecording || _recordedPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _recordedPath != null ? 'المدة: $_timerText' : _timerText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _isRecording
                        ? const Color(0xFFef4444)
                        : const Color(0xFF6C63FF),
                  ),
                ),
              ),
            GestureDetector(
              onTap: _isSending ? null : _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isRecording
                        ? [const Color(0xFFef4444), const Color(0xFFf97316)]
                        : _recordedPath != null
                            ? [const Color(0xFF10b981), const Color(0xFF059669)]
                            : [
                                const Color(0xFF6C63FF),
                                const Color(0xFFc084fc)
                              ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording
                              ? const Color(0xFFef4444)
                              : _recordedPath != null
                                  ? const Color(0xFF10b981)
                                  : const Color(0xFF6C63FF))
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording
                      ? Icons.stop_rounded
                      : _recordedPath != null
                          ? Icons.check_rounded
                          : Icons.mic,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'جاري التسجيل... اضغط للإيقاف'
                  : _recordedPath != null
                      ? 'تم التسجيل ✓ — يمكنك الإرسال الآن'
                      : 'اضغط للبدء في التسجيل',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isRecording
                    ? const Color(0xFFef4444)
                    : const Color(0xFF94a3b8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء',
                        style:
                            TextStyle(color: Color(0xFF94a3b8), fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_recordedPath == null || _isSending) ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('إرسال ✨',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
