import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/user_feedback_message.dart';

enum AppPopupNotificationType { success, error, warning, info }

OverlayEntry? _activePopupNotification;

void showAppPopupNotification(
  BuildContext context, {
  required String message,
  AppPopupNotificationType type = AppPopupNotificationType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final displayMessage = type == AppPopupNotificationType.error
      ? friendlyFeedbackMessage(message)
      : message;

  try {
    _activePopupNotification?.remove();
  } catch (_) {
    // The entry may already be closing from its own timer.
  }
  _activePopupNotification = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppPopupNotification(
      message: displayMessage,
      type: type,
      duration: duration,
      onDismissed: () {
        if (_activePopupNotification == entry) {
          _activePopupNotification = null;
        }
        try {
          entry.remove();
        } catch (_) {
          // Ignore duplicate dismiss calls from quick successive notifications.
        }
      },
    ),
  );

  _activePopupNotification = entry;
  overlay.insert(entry);
}

class _AppPopupNotification extends StatefulWidget {
  final String message;
  final AppPopupNotificationType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppPopupNotification({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppPopupNotification> createState() => _AppPopupNotificationState();
}

class _AppPopupNotificationState extends State<_AppPopupNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(widget.type);
    final icon = _iconForType(widget.type);

    return Positioned(
      top: 14,
      left: 18,
      right: 18,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _dismiss,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded,
                                color: Color(0xFF94A3B8), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForType(AppPopupNotificationType type) {
    return switch (type) {
      AppPopupNotificationType.success => const Color(0xFF059669),
      AppPopupNotificationType.error => const Color(0xFFEF4444),
      AppPopupNotificationType.warning => const Color(0xFFF97316),
      AppPopupNotificationType.info => const Color(0xFF0EA5E9),
    };
  }

  IconData _iconForType(AppPopupNotificationType type) {
    return switch (type) {
      AppPopupNotificationType.success => Icons.check_circle_rounded,
      AppPopupNotificationType.error => Icons.error_rounded,
      AppPopupNotificationType.warning => Icons.warning_amber_rounded,
      AppPopupNotificationType.info => Icons.notifications_rounded,
    };
  }
}
