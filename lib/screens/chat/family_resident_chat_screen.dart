import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/app_riverpod.dart';
import '../../services/ai_media_service.dart';
import '../../services/messages_service.dart';
import '../../services/realtime_service.dart';

class FamilyResidentChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserRole;
  final String? residentId;
  final Color accentColor;

  const FamilyResidentChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserRole,
    this.residentId,
    this.accentColor = const Color(0xFFea580c),
  });

  @override
  ConsumerState<FamilyResidentChatScreen> createState() =>
      _FamilyResidentChatScreenState();
}

class _FamilyResidentChatScreenState
    extends ConsumerState<FamilyResidentChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<BackendRoleMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _uploadingAttachment = false;
  String? _error;
  final _picker = ImagePicker();
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThread();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeSub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
    }
  }

  Future<void> _loadThread() async {
    try {
      final msgs = await MessagesService.instance.thread(
        widget.otherUserId,
        residentId: widget.residentId,
      );
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      await MessagesService.instance.markThreadRead(widget.otherUserId);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _subscribeRealtime() {
    _realtimeSub =
        RealtimeService.instance.liveEventsFor({'messages'}).listen((event) {
      final data = event['data'];
      if (data is! Map) return;
      final msg = BackendRoleMessage.fromJson(Map<String, dynamic>.from(data));
      if (msg.senderId != widget.otherUserId &&
          msg.recipientId != widget.otherUserId) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
      });
      _scrollToBottom();
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    try {
      final sent = await MessagesService.instance.send(
        recipientId: widget.otherUserId,
        body: text,
        residentId: widget.residentId,
      );
      if (!mounted) return;
      setState(() => _messages.add(sent));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الإرسال: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.image_rounded, color: Color(0xFF0369A1))),
              title: const Text('إرسال صورة'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FE),
                  child:
                      Icon(Icons.videocam_rounded, color: Color(0xFF7C3AED))),
              title: const Text('إرسال فيديو'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('إرسال الفيديو غير مدعوم حالياً'),
                      behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.insert_drive_file_rounded,
                      color: Color(0xFF059669))),
              title: const Text('إرسال ملف'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('إرسال الملفات غير مدعوم حالياً'),
                      behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (file == null || !mounted) return;

      setState(() => _uploadingAttachment = true);
      final upload = await AiMediaService.instance.uploadFile(
        filePath: file.path,
        residentId: ref.read(appRiverpod).backendResidentId,
      );
      if (!mounted) return;

      final sent = await MessagesService.instance.send(
        recipientId: widget.otherUserId,
        body: '📷 صورة',
        residentId: widget.residentId,
        mediaUrl: upload.mediaUrl ?? upload.id,
        mediaType: 'image',
      );
      if (!mounted) return;
      setState(() => _messages.add(sent));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل إرسال الصورة: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _myUserId => ref.read(appRiverpod).backendUserId ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                if (widget.otherUserRole != null)
                  Text(widget.otherUserRole!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: Color(0xFF94a3b8)),
              const SizedBox(height: 16),
              const Text('تعذر تحميل المحادثة',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadThread();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: widget.accentColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('لا توجد رسائل بعد',
                style: TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('ابدأ المحادثة بإرسال رسالة',
                style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i])
          .animate(delay: (30 * i).ms)
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.08, end: 0, duration: 200.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildBubble(BackendRoleMessage msg) {
    final isMe = msg.senderId == _myUserId;
    final time = _formatTime(msg.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: widget.accentColor.withValues(alpha: 0.15),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : '?',
                style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [
                              widget.accentColor,
                              widget.accentColor.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          isMe ? const Radius.circular(20) : Radius.zero,
                      bottomRight:
                          isMe ? Radius.zero : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.body,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF1e293b),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94a3b8))),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      color: Colors.white,
      child: Row(
        children: [
          // Attachment button
          GestureDetector(
            onTap: (_sending || _uploadingAttachment) ? null : _sendAttachment,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_sending || _uploadingAttachment)
                    ? Colors.grey.shade200
                    : widget.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: _uploadingAttachment
                  ? const Center(
                      child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : Icon(Icons.attach_file_rounded,
                      color: widget.accentColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _inputCtrl,
                textAlign: TextAlign.right,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94a3b8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sending ? Colors.grey.shade300 : widget.accentColor,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
