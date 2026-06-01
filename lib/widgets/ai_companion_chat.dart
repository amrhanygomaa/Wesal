import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/app_riverpod.dart';
import 'package:file_picker/file_picker.dart' as file_picker_lib;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'dart:math';
import 'package:lottie/lottie.dart';

// ─── حالات المساعد الصوتي ───────────────────────────────────────────
enum _VoiceState { idle, listening, thinking, speaking, done }

// ════════════════════════════════════════════════════════════════════
//  شاشة المحادثة الرئيسية مع الـ AI
// ════════════════════════════════════════════════════════════════════
class AICompanionChat extends ConsumerStatefulWidget {
  const AICompanionChat({super.key});

  @override
  ConsumerState<AICompanionChat> createState() => _AICompanionChatState();
}

class _AICompanionChatState extends ConsumerState<AICompanionChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  double _prevKeyboardHeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > _prevKeyboardHeight) {
      Future.delayed(const Duration(milliseconds: 350), _scrollToBottom);
    }
    _prevKeyboardHeight = keyboardHeight;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 400), _scrollToBottom);
      }
    });
    // Inject proactive greeting once when the chat is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeGreet();
    });
  }

  void _maybeGreet() {
    final provider = ref.read(appRiverpod);
    // Only greet if chat history is empty or last message is old (> 2 hours)
    final history = provider.companionChatHistory;
    final lastMsg = history.lastOrNull;
    final isStale = lastMsg == null ||
        DateTime.now().difference(lastMsg.timestamp).inHours >= 2;
    if (!isStale) return;

    // أولوية: nickname ← الاسم العربي الأول ← اسم الحساب
    final residentFile = provider.residentFiles
        .where((r) =>
            provider.backendResidentId != null &&
            r.id == provider.backendResidentId)
        .firstOrNull;
    String displayName;
    if (residentFile?.nickname?.isNotEmpty == true) {
      displayName = residentFile!.nickname!;
    } else if (residentFile != null && residentFile.name.isNotEmpty) {
      displayName = residentFile.name.trim().split(RegExp(r'\s+')).first;
    } else {
      displayName = (provider.currentAccount?.name ?? '').split(' ').first;
    }
    final title = displayName.isNotEmpty ? 'أستاذ $displayName' : 'صديقي';
    final missed = provider.medications
        .where((m) => m.isMissed && m.dayTag == 'اليوم')
        .toList();
    final upcoming =
        provider.activities.where((a) => a.status == 'coming').take(1).toList();

    String greeting;
    if (missed.isNotEmpty) {
      final names = missed.map((m) => m.name).take(2).join(' و');
      greeting = 'مرحباً $title 😊 لاحظت أنك لم تأخذ '
          '${missed.length == 1 ? 'دواء $names' : '${missed.length} أدوية'}. '
          'هل أنت بخير؟ هل تحتاج مساعدة؟';
    } else if (upcoming.isNotEmpty) {
      greeting = 'مرحباً $title! عندك نشاط "${upcoming.first.name}" '
          'الساعة ${upcoming.first.time}. كيف حالك اليوم؟';
    } else {
      greeting = 'مرحباً $title 😊 كيف تمر عليك اليوم؟ أنا هنا لأي شيء تحتاجه.';
    }

    provider.companionChatHistory.add(CompanionMessage(
      id: 'greet_${DateTime.now().millisecondsSinceEpoch}',
      text: greeting,
      isFromAI: true,
      timestamp: DateTime.now(),
    ));
    provider.refreshState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    // Second scroll after layout fully settles (keyboard animation complete)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickFile() async {
    final provider = ref.read(appRiverpod);
    final result = await file_picker_lib.FilePicker.platform.pickFiles(
      type: file_picker_lib.FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result != null) {
      final path = result.files.single.path;
      final name = result.files.single.name;
      final type =
          (name.endsWith('jpg') || name.endsWith('png')) ? 'image' : 'file';
      provider.sendCompanionMessage('', mediaPath: path, mediaType: type);
    }
  }

  void _openVoiceAssistant() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (ctx, anim, _) => const VoiceAssistantScreen(),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
    // لا يوجد انتظار للنتيجة — الشاشة تتحكم في الـ flow كاملاً
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    ref.listen<AppRiverpod>(appRiverpod, (prev, next) {
      if (prev?.companionChatHistory.length !=
          next.companionChatHistory.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8FAFC),
                Color(0xFFEEF2FF),
                Color(0xFFF1F5F9),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    children: [
                      Positioned(
                          top: 40,
                          left: -30,
                          child: _buildBlob(120,
                              const Color(0xFF6366F1).withValues(alpha: 0.07))),
                      Positioned(
                          bottom: 100,
                          right: -40,
                          child: _buildBlob(180,
                              const Color(0xFF8B5CF6).withValues(alpha: 0.07))),
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        itemCount: provider.companionChatHistory.length,
                        itemBuilder: (_, i) =>
                            _buildBubble(provider.companionChatHistory[i]),
                      ),
                    ],
                  ),
                ),
              ),
              _buildInputArea(provider),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          // أيقونة الـ AI
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 65,
                height: 65,
                child: Lottie.asset(
                  'assets/animations/Robot.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 30),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'رفيقي الذكي',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'نشط الآن',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // زر الصوت في الهيدر — واضح لكبار السن
          GestureDetector(
            onTap: _openVoiceAssistant,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat Bubble ──────────────────────────────────────────────────
  Widget _buildBubble(CompanionMessage msg) {
    final isAI = msg.isFromAI;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              width: 38,
              height: 38,
              child: Lottie.asset('assets/animations/Robot.json', repeat: true),
            ),
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment:
                  isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                if (msg.mediaPath != null) _buildMedia(msg),
                if (msg.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: isAI
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isAI ? Colors.white : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft:
                            isAI ? Radius.zero : const Radius.circular(24),
                        bottomRight:
                            isAI ? const Radius.circular(24) : Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAI
                              ? Colors.black.withValues(alpha: 0.05)
                              : const Color(0xFF6366F1).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                isAI ? FontWeight.w500 : FontWeight.bold,
                            color:
                                isAI ? const Color(0xFF334155) : Colors.white,
                            fontFamily: 'Cairo',
                            height: 1.6,
                          ),
                        ),
                        if (msg.sentiment != null &&
                            msg.sentiment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAI
                                  ? const Color(0xFFF1F5F9)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.psychology_outlined,
                                    size: 14,
                                    color: isAI
                                        ? const Color(0xFF64748B)
                                        : Colors.white),
                                const SizedBox(width: 4),
                                Text('التحليل الصوتي: ${msg.sentiment}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isAI
                                            ? const Color(0xFF64748B)
                                            : Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!isAI)
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 15, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia(CompanionMessage msg) {
    if (msg.mediaType == 'image' && msg.mediaPath != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(File(msg.mediaPath!),
              width: 200, height: 150, fit: BoxFit.cover),
        ),
      );
    }
    if (msg.mediaType == 'file') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_rounded, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text('ملف مرفق',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Color(0xFF334155))),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Input Area ───────────────────────────────────────────────────
  Widget _buildInputArea(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الملف
          _buildIconBtn(
            icon: Icons.attach_file_rounded,
            color: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF64748B),
            onTap: _pickFile,
          ),
          const SizedBox(width: 10),
          // حقل النص
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Cairo'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        provider.sendCompanionMessage(text);
                        _messageController.clear();
                        _scrollToBottom();
                      }
                    },
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFF6366F1), size: 28),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // زر الميكروفون — يفتح المساعد الصوتي
          _buildIconBtn(
            icon: Icons.mic_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            iconColor: Colors.white,
            onTap: _openVoiceAssistant,
            size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Gradient? gradient,
    Color? iconColor,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? const Color(0xFFF1F5F9)) : null,
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child:
            Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 22),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

enum _RayWave { sine, triangle, saw }

class _RayTone {
  const _RayTone(
    this.frequency,
    this.start,
    this.duration, {
    this.gain = 0.12,
    this.wave = _RayWave.sine,
  });

  final double frequency;
  final double start;
  final double duration;
  final double gain;
  final _RayWave wave;
}

class _RayVoiceSfx {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;

  Future<void> boot() => _play(const [
        _RayTone(440, 0.00, 0.18, gain: 0.12),
        _RayTone(554, 0.12, 0.18, gain: 0.12),
        _RayTone(659, 0.24, 0.18, gain: 0.12),
        _RayTone(880, 0.36, 0.34, gain: 0.08),
        _RayTone(1108, 0.36, 0.34, gain: 0.08),
      ], 0.78);

  Future<void> disconnect() => _play(const [
        _RayTone(659, 0.00, 0.15, gain: 0.1),
        _RayTone(554, 0.10, 0.15, gain: 0.1),
        _RayTone(440, 0.20, 0.25, gain: 0.1),
      ], 0.5);

  Future<void> wake() => _play(const [
        _RayTone(880, 0.00, 0.1, gain: 0.14),
        _RayTone(1108, 0.10, 0.15, gain: 0.16),
      ], 0.32);

  Future<void> mute() => _play(const [
        _RayTone(330, 0.00, 0.12, gain: 0.1, wave: _RayWave.triangle),
      ], 0.2);

  Future<void> unmute() => _play(const [
        _RayTone(660, 0.00, 0.1, gain: 0.12, wave: _RayWave.triangle),
      ], 0.2);

  Future<void> confirm() => _play(const [
        _RayTone(523, 0.00, 0.12, gain: 0.1, wave: _RayWave.triangle),
        _RayTone(784, 0.10, 0.2, gain: 0.12, wave: _RayWave.triangle),
      ], 0.36);

  Future<void> error() => _play(const [
        _RayTone(220, 0.00, 0.25, gain: 0.12, wave: _RayWave.saw),
        _RayTone(233, 0.00, 0.25, gain: 0.08, wave: _RayWave.saw),
      ], 0.32);

  Future<void> _play(List<_RayTone> tones, double seconds) async {
    if (_disposed) return;
    try {
      await _player.stop();
      await _player.play(
        BytesSource(_wavForTones(tones, seconds), mimeType: 'audio/wav'),
      );
    } catch (e) {
      debugPrint('[VoiceSfx] play failed: $e');
    }
  }

  Uint8List _wavForTones(List<_RayTone> tones, double seconds) {
    const sampleRate = 44100;
    final samples = (sampleRate * seconds).ceil();
    final data = ByteData(44 + samples * 2);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + samples * 2, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, samples * 2, Endian.little);

    for (var i = 0; i < samples; i++) {
      final t = i / sampleRate;
      var mixed = 0.0;
      for (final tone in tones) {
        if (t < tone.start || t > tone.start + tone.duration) continue;
        final local = t - tone.start;
        final phase = 2 * pi * tone.frequency * local;
        final wave = switch (tone.wave) {
          _RayWave.triangle => (2 / pi) * asin(sin(phase)),
          _RayWave.saw => 2 *
              ((local * tone.frequency) -
                  (local * tone.frequency + 0.5).floor()),
          _RayWave.sine => sin(phase),
        };
        final attack = min(0.015, tone.duration * 0.25);
        final release = min(0.08, tone.duration * 0.45);
        final fadeIn = attack <= 0 ? 1.0 : min(1.0, local / attack);
        final fadeOut =
            release <= 0 ? 1.0 : min(1.0, (tone.duration - local) / release);
        mixed += wave * tone.gain * min(fadeIn, fadeOut);
      }
      final clamped = mixed < -1.0
          ? -1.0
          : mixed > 1.0
              ? 1.0
              : mixed;
      data.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
    }

    return data.buffer.asUint8List();
  }

  void dispose() {
    _disposed = true;
    unawaited(_player.dispose());
  }
}

// ════════════════════════════════════════════════════════════════════
//  شاشة المساعد الصوتي — phone call style
// ════════════════════════════════════════════════════════════════════
class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _waveCtrl;
  final _sfx = _RayVoiceSfx();

  // ── Speech recognition & playback ─────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _sessionActive = false;
  bool _isSubmittingSpeech = false;
  String _recognizedText = '';
  String _lastSpeechError = '';

  bool _isMuted = false;

  _VoiceState _state = _VoiceState.idle;
  bool _isStarting = false; // يمنع double-tap
  bool _isPopping = false;
  String _userSpoken = '';
  String _aiResponse = '';
  String _errorMessage = '';


  bool get _isMicPermissionError =>
      _errorMessage.contains('ميكروفون') ||
      _errorMessage.contains('صلاحية') ||
      _errorMessage.contains('permission');

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_sfx.boot());
      if (mounted) _startRecording();
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _waveCtrl.dispose();
    try {
      _speech.cancel();
    } catch (_) {}
    try {
      ref.read(appRiverpod).stopReading();
    } catch (_) {}
    _sfx.dispose();
    super.dispose();
  }

  // ── طلب صلاحية الميكروفون ───────────────────────────────────────
  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    debugPrint('[Voice] mic permission status: $status');
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showError('صلاحية الميكروفون مرفوضة — افتح الإعدادات وفعّلها');
      return false;
    }
    final result = await Permission.microphone.request();
    debugPrint('[Voice] mic permission after request: $result');
    if (result.isGranted) return true;
    _showError('محتاجين صلاحية الميكروفون عشان نسمعك');
    return false;
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechReady) return true;

    try {
      _speechReady = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: (error) {
          _lastSpeechError = error.errorMsg;
          debugPrint(
            '[Voice] speech error: ${error.errorMsg} | permanent=${error.permanent}',
          );
        },
      );
    } catch (e, st) {
      debugPrint('[Voice] speech initialize exception: $e\n$st');
      _speechReady = false;
    }

    if (!_speechReady) {
      _showError('التعرّف على الكلام غير متاح على الجهاز');
    }
    return _speechReady;
  }

  void _handleSpeechStatus(String status) {
    debugPrint('[Voice] speech status: $status');
    final normalized = status.toLowerCase();
    final stopped = normalized == 'done' || normalized == 'notlistening';

    if (!stopped || _isMuted || !_sessionActive) return;

    if (_state == _VoiceState.speaking) {
      return;
    }

    if (_state != _VoiceState.listening || _isSubmittingSpeech) {
      return;
    }

    if (_recognizedText.trim().isEmpty) {
      _scheduleRestartListening(const Duration(milliseconds: 500));
      return;
    }

    Future.microtask(_stopRecordingAndSend);
  }

  void _scheduleRestartListening(
      [Duration delay = const Duration(milliseconds: 550)]) {
    if (!_sessionActive || _isPopping || _isMuted) return;
    Future.delayed(delay, () {
      if (!mounted || !_sessionActive || _isPopping || _isMuted) return;
      if (_state == _VoiceState.idle || _state == _VoiceState.done) {
        _startRecording();
      }
    });
  }

  void _showError(String msg) {
    debugPrint('[Voice] ❌ showError: $msg');
    unawaited(_sfx.error());
    if (!mounted) {
      _isSubmittingSpeech = false;
      return;
    }
    setState(() {
      _errorMessage = msg;
      _state = _VoiceState.idle;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _errorMessage = '');
    });
  }

  // ── ابدأ الاستماع ────────────────────────────────────────────────
  Future<void> _startRecording({bool isBargeIn = false}) async {
    if (_isStarting || _isMuted) {
      return;
    }
    if (_state == _VoiceState.listening || _state == _VoiceState.thinking) {
      return;
    }
    _sessionActive = true;
    _isStarting = true;
    try {
      final hasMic = await _ensureMicPermission();
      if (!hasMic) return;

      final speechReady = await _ensureSpeechReady();
      if (!speechReady) return;

      _recognizedText = '';
      _lastSpeechError = '';

      if (!isBargeIn) {
        await ref.read(appRiverpod).stopReading();
        if (!mounted) return;
        setState(() {
          _state = _VoiceState.listening;
          _userSpoken = '';
          _aiResponse = '';
          _errorMessage = '';
        });
        unawaited(_sfx.unmute());
      }

      debugPrint('[Voice] 🎤 speech listen started (bargeIn=$isBargeIn)');
      await _speech.listen(
        localeId: 'ar_EG',
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 2),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          _recognizedText = words;
          
          if (_state == _VoiceState.speaking) {
             _interruptAndRestart(words);
          } else {
             if (mounted) setState(() => _userSpoken = words);
          }
          debugPrint(
            '[Voice] transcript partial=${!result.finalResult}: "$words"',
          );
        },
      );
    } catch (e, st) {
      debugPrint('[Voice] startListening exception: $e\n$st');
      if (!isBargeIn) _showError('تعذّر تشغيل الاستماع، حاول مرة أخرى');
    } finally {
      _isStarting = false;
    }
  }

  // ── أوقف الاستماع وأرسل النص للباك اند ──────────────────────────
  Future<void> _stopRecordingAndSend() async {
    if (_isSubmittingSpeech) return;
    _isSubmittingSpeech = true;
    debugPrint('[Voice] 🛑 stopping speech recognition');
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('[Voice] speech.stop exception: $e');
    }

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 250));

    final transcript = _recognizedText.trim();
    debugPrint('[Voice] final transcript: "$transcript"');

    if (transcript.isEmpty) {
      final reason = _lastSpeechError.isEmpty ? '' : ' ($_lastSpeechError)';
      debugPrint('[Voice] no speech detected$reason');
      _showError('لم أسمعك بوضوح، حاول مرة تانية');
      _isSubmittingSpeech = false;
      _scheduleRestartListening(const Duration(milliseconds: 900));
      return;
    }

    try {
      setState(() {
        _state = _VoiceState.thinking;
        _userSpoken = transcript;
      });
      unawaited(_sfx.confirm());

      debugPrint('[Voice] 📤 send transcript through /ai/chat');
      final reply = await ref
          .read(appRiverpod)
          .sendCompanionMessage(transcript, voiceMode: true);

      if (!mounted) {
        _isSubmittingSpeech = false;
        return;
      }

      final cleanReply = reply?.trim() ?? '';
      if (cleanReply.isEmpty) {
        _isSubmittingSpeech = false;
        _showError('فشل الحصول على رد، حاول مرة تانية');
        _scheduleRestartListening(const Duration(milliseconds: 1200));
        return;
      }

      debugPrint('[Voice] 📥 reply: "$cleanReply"');
      setState(() {
        _aiResponse = cleanReply;
        _state = _VoiceState.speaking;
      });
      unawaited(_sfx.wake());

      if (!_isMuted) {
        _startRecording(isBargeIn: true);
      }

      await ref.read(appRiverpod).startCompanionSpeech(cleanReply);
      _isSubmittingSpeech = false;
      if (!mounted) return;
      if (!ref.read(appRiverpod).isReadingAudio &&
          _state == _VoiceState.speaking) {
        setState(() => _state = _VoiceState.done);
        _scheduleRestartListening();
      }
    } catch (e, st) {
      debugPrint('[Voice] voice flow exception: $e\n$st');
      _isSubmittingSpeech = false;
      _showError('فشل الاتصال بالخادم، حاول مرة تانية');
      _scheduleRestartListening(const Duration(milliseconds: 1200));
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _state = _VoiceState.idle;
        try {
          if (_speech.isListening) _speech.cancel();
          ref.read(appRiverpod).stopReading();
        } catch (_) {}
      } else {
        _startRecording();
      }
    });
  }

  Future<void> _interruptAndRestart([String initialWords = '']) async {
    debugPrint('[Voice] 🛑 interrupt requested with words: "$initialWords"');
    try {
      await ref.read(appRiverpod).stopReading();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _state = _VoiceState.listening;
      _userSpoken = initialWords;
      _aiResponse = '';
      _errorMessage = '';
    });
    unawaited(_sfx.wake());
    // Since _speech is already listening, we just let it continue.
    // It will trigger _handleSpeechStatus('done') when the user stops.
  }

  void _close() {
    if (_isPopping) return;
    _isPopping = true;
    _sessionActive = false;
    try {
      if (_speech.isListening) _speech.cancel();
    } catch (_) {}
    try {
      ref.read(appRiverpod).stopReading();
    } catch (_) {}
    unawaited(_sfx.disconnect());
    Navigator.pop(context);
  }

  // ── الشكل المركزي (Glowing Orb) ─────────────────────────────────────────
  Widget _buildGlowingOrb() {
    final active = _state == _VoiceState.listening || _state == _VoiceState.speaking;
    final thinking = _state == _VoiceState.thinking;

    return AnimatedBuilder(
      animation: _ringCtrl,
      builder: (_, __) {
        final t = _ringCtrl.value;
        final float = sin(t * 2 * pi) * 12;
        final scale = active ? 1.0 + sin(t * 2 * pi) * 0.05 : (thinking ? 1.0 + sin(t * 4 * pi) * 0.03 : 1.0);

        final color1 = active ? const Color(0xFF9D4EDD) : (thinking ? const Color(0xFFC77DFF) : const Color(0xFFB0B0B0));
        final color2 = active ? const Color(0xFF48BFE3) : (thinking ? const Color(0xFF5E60CE) : const Color(0xFFD3D3D3));

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(0, float + 110),
              child: Container(
                width: 100,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: color1.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 5,
                    )
                  ]
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, float),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color2, color1],
                      center: const Alignment(-0.2, -0.3),
                      radius: 0.8,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color1.withValues(alpha: active ? 0.6 : 0.3),
                        blurRadius: 40,
                        spreadRadius: active ? 10 : 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: -5,
                        offset: const Offset(-5, -5),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOrbEye(height: active ? 22 : (thinking ? 12 : 16)),
                      const SizedBox(width: 20),
                      _buildOrbEye(height: active ? 22 : (thinking ? 12 : 16)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrbEye({required double height}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // ── نص الحالة المحدّث ────────────────────────────────────────────
  String get _residentTitle {
    final firstName = (ref.read(appRiverpod).currentAccount?.name ??
            ref.read(appRiverpod).currentUser.name)
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .firstOrNull;
    return firstName == null ? 'صديقي' : 'أستاذ $firstName';
  }

  String get _stateLabel {
    if (_errorMessage.isNotEmpty) {
      return _isMicPermissionError ? 'تعذّر الوصول للميكروفون' : 'حدث خطأ';
    }
    if (_isMuted) return 'الميكروفون مكتوم';
    switch (_state) {
      case _VoiceState.idle:
        return 'أنا معاك يا $_residentTitle';
      case _VoiceState.listening:
        return 'سامعك كويس...';
      case _VoiceState.thinking:
        // Removed "Thinking" indicator to make it more seamless
        return 'سامعك كويس...';
      case _VoiceState.speaking:
        return 'وناس يتحدث...';
      case _VoiceState.done:
        return 'نكمل كلامنا؟';
    }
  }

  String get _subLabel {
    if (_isMicPermissionError) return 'يرجى السماح باستخدام الميكروفون';
    if (_errorMessage.isNotEmpty) return _errorMessage;
    if (_isMuted) return 'اضغط على الميكروفون للبدء';
    switch (_state) {
      case _VoiceState.idle:
      case _VoiceState.done:
        return 'تحدث مباشرة، أنا أستمع';
      case _VoiceState.listening:
      case _VoiceState.thinking:
        return 'قول اللي في بالك بهدوء';
      case _VoiceState.speaking:
        return 'تحدث في أي وقت لمقاطعتي';
    }
  }

  // ── منطقة النص (Transcript) ────────────────────────────────────────
  Widget _buildModernTranscript() {
    final text = _userSpoken.isNotEmpty
        ? _userSpoken
        : (_aiResponse.isNotEmpty ? _aiResponse : _subLabel);
        
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          text,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: Color(0xFF2B2D42),
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ── زر كتم المايكروفون الوحيد ─────────────────────────────────────
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.only(bottom: 40),
      child: GestureDetector(
        onTap: _toggleMute,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isMuted ? Colors.white : const Color(0xFFEF4444),
            border: Border.all(
              color: _isMuted ? const Color(0xFFEF4444) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              if (!_isMuted)
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                )
            ]
          ),
          child: Icon(
            _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: _isMuted ? const Color(0xFFEF4444) : Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppRiverpod>(appRiverpod, (prev, next) {
      if (prev?.isReadingAudio == true &&
          !next.isReadingAudio &&
          _state == _VoiceState.speaking &&
          mounted) {
        _isSubmittingSpeech = false;
        setState(() => _state = _VoiceState.done);
        _scheduleRestartListening();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFfafaf9),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isMuted 
                      ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)] 
                      : [const Color(0xFFF6F0FF), const Color(0xFFEAF5FF)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _close,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                Text(
                   _stateLabel,
                   style: const TextStyle(
                     color: Color(0xFF8D99AE),
                     fontFamily: 'Cairo',
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                   ),
                ),
                
                const Spacer(),
                
                _buildGlowingOrb(),
                
                const SizedBox(height: 70),
                
                _buildModernTranscript(),
                
                const Spacer(),
                
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


