import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_riverpod.dart';

class SpecialistChatDetailScreen extends ConsumerStatefulWidget {
  final String familyName;
  final String residentName;

  const SpecialistChatDetailScreen(
      {super.key, required this.familyName, required this.residentName});

  @override
  ConsumerState<SpecialistChatDetailScreen> createState() =>
      _SpecialistChatDetailScreenState();
}

class _SpecialistChatDetailScreenState
    extends ConsumerState<SpecialistChatDetailScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    // Listen for new messages
    ref.listen<AppRiverpod>(appRiverpod, (previous, next) {
      if (previous?.specialistChatHistory.length !=
          next.specialistChatHistory.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFea580c),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFFfed7aa), shape: BoxShape.circle),
              child: Center(
                  child: Text(widget.familyName.substring(0, 2),
                      style: const TextStyle(
                          color: Color(0xFFc2410c),
                          fontSize: 14,
                          fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.familyName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('متابع حالة: ${widget.residentName}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: provider.specialistChatHistory.length,
                itemBuilder: (context, index) {
                  final msg = provider.specialistChatHistory[index];
                  // Invert the isFromMe logic since this is the specialist view
                  return _buildChatBubble(msg, !msg.isFromMe);
                },
              ),
            ),
            _buildInputArea(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: Color(0xFFfed7aa), shape: BoxShape.circle),
              child: Center(
                  child: Text(widget.familyName.substring(0, 2),
                      style: const TextStyle(
                          color: Color(0xFFc2410c),
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
            ),
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFFea580c), Color(0xFFf97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomRight:
                          isMe ? const Radius.circular(24) : Radius.zero,
                      bottomLeft:
                          isMe ? Radius.zero : const Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isMe ? FontWeight.w500 : FontWeight.bold,
                      color: isMe ? Colors.white : const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  size: 14, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'اكتب ردك هنا...',
                        hintStyle:
                            TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_messageController.text.isNotEmpty) {
                        provider.sendSpecialistReply(_messageController.text);
                        _messageController.clear();
                      }
                    },
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFFea580c), size: 28),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
