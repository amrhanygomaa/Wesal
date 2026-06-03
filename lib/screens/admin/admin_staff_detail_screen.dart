import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../widgets/taptaba_scaffold.dart';

ImageProvider<Object>? _staffImageProvider(String? imageUrl) {
  final value = imageUrl?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('/') && !value.startsWith('//')) {
    return NetworkImage('${ApiConfig.baseUrl}$value');
  }
  final uri = Uri.tryParse(value);
  if (uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(value);
  }
  return FileImage(File(value));
}

class AdminStaffDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  final String name;
  final String role;
  final double rate;
  final String status;
  final String time;

  const AdminStaffDetailScreen({
    super.key,
    required this.staffId,
    required this.name,
    required this.role,
    required this.rate,
    required this.status,
    required this.time,
  });

  @override
  ConsumerState<AdminStaffDetailScreen> createState() =>
      _AdminStaffDetailScreenState();
}

class _AdminStaffDetailScreenState
    extends ConsumerState<AdminStaffDetailScreen> {
  bool _isSavingStaff = false;

  StaffPerformance _currentStaff(AppRiverpod provider) {
    return provider.staffPerformanceList.firstWhere(
      (s) => s.id == widget.staffId,
      orElse: () => StaffPerformance(
        id: widget.staffId,
        name: widget.name,
        role: widget.role,
        completionRate: widget.rate,
        lastActive: widget.time,
        status: widget.status,
      ),
    );
  }

  bool _isNurseRole(String role) {
    return role == 'Nurse' || role == 'ممرض';
  }

  String _roleTitle(String role) {
    if (_isNurseRole(role)) return 'طاقم التمريض';
    return 'أخصائي اجتماعي';
  }

  String _qualificationForRole(String role) {
    return _isNurseRole(role) ? 'بكالوريوس تمريض' : 'ليسانس آداب قسم اجتماع';
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final staff = _currentStaff(provider);
    final isNurse = _isNurseRole(staff.role);
    final isOnline = staff.status == 'online';

    return TaptabaScaffold(
      title: 'ونس',
      titleColor: const Color(0xFF0F172A),
      overrideRole: 'مدير',
      body: DefaultTabController(
        length: 3,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildProfileHeader(context, staff, isNurse, isOnline),
              const TabBar(
                labelColor: Color(0xFF0ea5e9),
                unselectedLabelColor: Color(0xFF64748b),
                indicatorColor: Color(0xFF0ea5e9),
                tabs: [
                  Tab(text: 'الأداء والإنجاز'),
                  Tab(text: 'البيانات الشخصية'),
                  Tab(text: 'المستندات'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Performance
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoCard(
                            'الأداء والإنجاز',
                            [
                              const Text('معدل إنجاز المهام اليومية',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF64748b))),
                              const SizedBox(height: 8),
                              _buildCompletionBar(staff.completionRate),
                            ],
                            onEdit: () => _showEditStaffSheet(context, staff)),
                      ],
                    ),
                    // Tab 2: Personal Info
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoCard(
                            'البيانات الشخصية والمهنية',
                            [
                              _infoRow(
                                  'الرقم الوظيفي',
                                  'EMP-${staff.name.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}',
                                  Icons.badge_outlined),
                              _infoRow('الرقم القومي', '29501012345678',
                                  Icons.credit_card_outlined),
                              _infoRow(
                                  'البريد الإلكتروني',
                                  '${staff.name.replaceAll(' ', '.').toLowerCase()}@tbtba.com',
                                  Icons.email_outlined),
                              _infoRow(
                                  'المؤهل',
                                  _qualificationForRole(staff.role),
                                  Icons.school_outlined),
                              if (isNurse) ...[
                                _infoRow('القسم', 'العناية المركزة',
                                    Icons.local_hospital_outlined),
                                _infoRow('الوردية', 'صباحية (8 ص - 4 م)',
                                    Icons.schedule_rounded),
                              ] else ...[
                                _infoRow('القسم', 'الدعم النفسي والاجتماعي',
                                    Icons.psychology_outlined),
                                _infoRow('الحالات المتابعة', '12 حالة',
                                    Icons.people_outline),
                              ],
                            ],
                            onEdit: () => _showEditStaffSheet(context, staff)),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showDeleteConfirmation(context, staff),
                          icon: const Icon(Icons.delete_forever_rounded,
                              color: Colors.redAccent, size: 20),
                          label: const Text('حذف ملف الموظف نهائياً',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                    // Tab 3: Documents
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoCard('المستندات ومسوغات التعيين', [
                          _infoRow('الفيش الجنائي', 'تم الاستلام (ساري)',
                              Icons.assignment_turned_in_outlined,
                              valColor: Colors.green),
                          _infoRow('شهادة التخرج', 'تم الاستلام',
                              Icons.card_membership_outlined),
                          _infoRow(
                              'ترخيص مزاولة المهنة',
                              isNurse ? 'تم الاستلام (ساري)' : 'غير مطلوب',
                              isNurse
                                  ? Icons.verified_user_outlined
                                  : Icons.block_flipped,
                              valColor: isNurse ? Colors.green : Colors.grey),
                          _infoRow('تاريخ التعيين', '01/01/2025',
                              Icons.calendar_today_outlined),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, StaffPerformance staff,
      bool isNurse, bool isOnline) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('ملف الموظف',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(
                    _isSavingStaff
                        ? Icons.hourglass_top_rounded
                        : Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 28),
                onPressed: _isSavingStaff
                    ? null
                    : () => _showEditStaffSheet(context, staff),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Hero(
                  tag: widget.staffId,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final provider = ref.watch(appRiverpod);
                      final staffList = provider.staffPerformanceList;
                      final displayedStaff = staffList.firstWhere(
                        (s) => s.id == widget.staffId,
                        orElse: () => StaffPerformance(
                          id: widget.staffId,
                          name: staff.name,
                          role: staff.role,
                          completionRate: staff.completionRate,
                          lastActive: staff.lastActive,
                          status: staff.status,
                        ),
                      );

                      final String? imageUrl = displayedStaff.imageUrl;
                      final imageProvider = _staffImageProvider(imageUrl);

                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white12,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 60)
                            : null,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final saved = await ref
                        .read(appRiverpod)
                        .pickAndSetStaffImage(widget.staffId);
                    if (!mounted || saved == null) return;
                    final error = ref.read(appRiverpod).backendSyncError;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(saved
                            ? 'تم حفظ صورة الموظف بنجاح'
                            : 'تم اختيار الصورة محلياً، لكن فشل حفظها على السيرفر: ${error ?? 'حاول مرة أخرى'}'),
                        backgroundColor: saved
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0ea5e9),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF1e293b), width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            staff.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _roleTitle(staff.role),
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'نشط' : 'غير نشط',
                style: TextStyle(
                    fontSize: 14,
                    color: isOnline
                        ? Colors.greenAccent
                        : Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children,
      {VoidCallback? onEdit}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369a1))),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded,
                          size: 18, color: Colors.blueAccent),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
              const Divider(
                  height: 25, color: Color(0xFFf1f5f9), thickness: 1.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon,
      {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF0ea5e9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94a3b8))),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: valColor ?? const Color(0xFF1e293b)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBar(double rate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(rate * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0ea5e9))),
            Text(rate >= 0.8 ? 'ممتاز' : 'جيد',
                style: TextStyle(
                    fontSize: 12,
                    color: rate >= 0.8 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: const Color(0xFFf1f5f9),
            valueColor: AlwaysStoppedAnimation<Color>(rate >= 0.8
                ? const Color(0xFF10b981)
                : const Color(0xFF0ea5e9)),
          ),
        ),
      ],
    );
  }

  void _showEditStaffSheet(BuildContext context, StaffPerformance staff) {
    final nameController = TextEditingController(text: staff.name);
    var selectedRole = _isNurseRole(staff.role) ? 'Nurse' : 'ClinicalStaff';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تعديل بيانات الموظف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الدور الوظيفي',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleChoice(
                            label: 'تمريض',
                            icon: Icons.medical_services_outlined,
                            selected: selectedRole == 'Nurse',
                            onTap: () =>
                                setModalState(() => selectedRole = 'Nurse'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildRoleChoice(
                            label: 'أخصائي اجتماعي',
                            icon: Icons.psychology_outlined,
                            selected: selectedRole == 'ClinicalStaff',
                            onTap: () => setModalState(
                                () => selectedRole = 'ClinicalStaff'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _isSavingStaff
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(const SnackBar(
                                  content: Text('اكتب اسم الموظف أولاً'),
                                  backgroundColor: Color(0xFFef4444),
                                ));
                                return;
                              }

                              setState(() => _isSavingStaff = true);
                              final updated = staff.copyWith(
                                name: name,
                                role: selectedRole,
                              );
                              final provider = ref.read(appRiverpod);
                              await provider.updateStaff(updated);
                              if (!mounted) return;
                              setState(() => _isSavingStaff = false);

                              if (!sheetContext.mounted) return;
                              if (provider.backendSyncError != null) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(SnackBar(
                                  content: Text(provider.backendSyncError!),
                                  backgroundColor: const Color(0xFFef4444),
                                ));
                                return;
                              }

                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حفظ بيانات الموظف بنجاح'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            },
                      icon: _isSavingStaff
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text(
                        'حفظ التعديلات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ea5e9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      nameController.dispose();
      if (mounted && _isSavingStaff) {
        setState(() => _isSavingStaff = false);
      }
    });
  }

  Widget _buildRoleChoice({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0ea5e9) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected
                    ? const Color(0xFF0369A1)
                    : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? const Color(0xFF0369A1)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StaffPerformance staff) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد الحذف النهائي ⚠️',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف ملف الموظف "${staff.name}" بالكامل؟ لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final deleted = await ref.read(appRiverpod).deleteStaff(staff.id);
              if (!parentContext.mounted) return;
              if (!deleted || ref.read(appRiverpod).backendSyncError != null) {
                ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                  content: Text(ref.read(appRiverpod).backendSyncError ??
                      'تعذر حذف ملف الموظف، حاول مرة أخرى'),
                  backgroundColor: const Color(0xFFef4444),
                ));
                return;
              }
              Navigator.pop(parentContext); // Go back to list
              ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(
                content: Text('تم حذف ملف الموظف بنجاح'),
                backgroundColor: Color(0xFF10B981),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('نعم، احذف الملف'),
          ),
        ],
      ),
    );
  }
}
