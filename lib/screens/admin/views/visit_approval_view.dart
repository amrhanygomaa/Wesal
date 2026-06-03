import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import '../../../widgets/app_popup_notification.dart';

class VisitApprovalView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations;

  const VisitApprovalView({super.key, required this.fadeAnimations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    final pendingVisits = provider.familyVisits.where(_isPendingVisit).toList();

    return Column(
      children: [
        _buildHeader(pendingVisits.length),
        if (pendingVisits.isEmpty)
          _buildEmptyState()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(pendingVisits.length, (index) {
                final v = pendingVisits[index];
                return FadeTransition(
                  opacity: fadeAnimations[index % fadeAnimations.length],
                  child: _buildVisitRequestCard(context, ref, v),
                );
              }),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  bool _isPendingVisit(FamilyVisit visit) {
    final status = visit.status.toLowerCase().trim();
    return status == 'pending' ||
        status == 'requested' ||
        status == 'waiting' ||
        status == 'new' ||
        status == 'submitted' ||
        status.contains('pending') ||
        status.contains('await') ||
        status.contains('معلق') ||
        status.contains('انتظار');
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('طلبات الزيارة المعلقة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFfee2e2),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$count طلبات',
                style: const TextStyle(
                    color: Color(0xFFb91c1c),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Color(0xFFf8fafc), shape: BoxShape.circle),
            child: Icon(Icons.event_available_rounded,
                size: 48, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد طلبات زيارة حالياً',
              style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVisitRequestCard(
      BuildContext context, WidgetRef ref, FamilyVisit v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/icons/calendar.png', width: 14, height: 14),
              const SizedBox(width: 8),
              Text(v.date,
                  style: const TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildTypeBadge(v.type),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_circle_rounded,
                  size: 40, color: Color(0xFFcbd5e1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الزائر: ${v.visitorName}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    Text('الموعد: ${v.date} - ${v.time}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748b))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFf1f5f9)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final provider = ref.read(appRiverpod);
                    final ok = await provider.approveVisit(v.id);
                    if (!context.mounted) return;
                    _showActionFeedback(
                      context,
                      ok
                          ? 'تمت الموافقة على الزيارة بنجاح'
                          : (provider.backendSyncError ??
                              'تعذر تحديث حالة الزيارة'),
                      isError: !ok,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFdcfce7),
                    foregroundColor: const Color(0xFF166534),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('موافقة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final provider = ref.read(appRiverpod);
                    final ok = await provider.rejectVisit(v.id);
                    if (!context.mounted) return;
                    _showActionFeedback(
                      context,
                      ok
                          ? 'تم رفض طلب الزيارة'
                          : (provider.backendSyncError ??
                              'تعذر تحديث حالة الزيارة'),
                      isError: !ok,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFfee2e2)),
                    foregroundColor: const Color(0xFFb91c1c),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('رفض',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    bool isPhysical = type == 'physical';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPhysical ? const Color(0xFFeff6ff) : const Color(0xFFf5f3ff),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPhysical ? Icons.people_alt_rounded : Icons.videocam_rounded,
              size: 12,
              color: isPhysical
                  ? const Color(0xFF2563eb)
                  : const Color(0xFF7c3aed)),
          const SizedBox(width: 6),
          Text(isPhysical ? 'لقاء مودة' : 'مكالمة فيديو',
              style: TextStyle(
                  color: isPhysical
                      ? const Color(0xFF2563eb)
                      : const Color(0xFF7c3aed),
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showActionFeedback(BuildContext context, String msg,
      {bool isError = false}) {
    showAppPopupNotification(
      context,
      message: msg,
      type: isError
          ? AppPopupNotificationType.error
          : AppPopupNotificationType.success,
      duration: const Duration(seconds: 3),
    );
  }
}
