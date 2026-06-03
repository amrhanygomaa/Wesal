import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api_config.dart';
import '../../../providers/app_riverpod.dart';
import '../admin_staff_detail_screen.dart';

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

class StaffManagementView extends StatelessWidget {
  final List<Animation<double>> fadeAnimations;

  const StaffManagementView({super.key, required this.fadeAnimations});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(appRiverpod);
        final staffList = provider.staffPerformanceList;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStaffSummary(provider),
                    const SizedBox(height: 24),
                    const Text('قائمة الطاقم العملي الرسمي',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 16),
                    ...staffList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final s = entry.value;
                      return FadeTransition(
                        opacity: fadeAnimations[index % fadeAnimations.length],
                        child: _buildStaffCard(
                            context,
                            ref,
                            s.id,
                            s.name,
                            s.role,
                            s.completionRate,
                            s.status,
                            s.lastActive,
                            s.imageUrl),
                      );
                    }),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddStaffSheet(context, ref),
                  backgroundColor: const Color(0xFF0ea5e9),
                  icon: const Icon(Icons.add_moderator_rounded,
                      color: Colors.white),
                  label: const Text('إضافة موظف',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddStaffSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'ممرض';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text('تسجيل موظف جديد 📋',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              const Text(
                  'قم بإضافة بيانات العضو الجديد للطاقم الطبي أو الإداري',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
              const SizedBox(height: 24),
              _buildField(nameController, 'الاسم الكامل'),
              const SizedBox(height: 12),
              _buildField(emailController, 'البريد الإلكتروني'),
              const SizedBox(height: 12),
              _buildField(passwordController, 'كلمة المرور الإفتراضية'),
              const SizedBox(height: 20),
              const Text('الدور الوظيفي',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  _buildRoleTag('ممرض', 'تمريض', selectedRole == 'ممرض',
                      () => setModalState(() => selectedRole = 'ممرض')),
                  _buildRoleTag(
                      'أخصائي اجتماعي',
                      'أخصائي',
                      selectedRole == 'أخصائي اجتماعي',
                      () =>
                          setModalState(() => selectedRole = 'أخصائي اجتماعي')),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        emailController.text.isNotEmpty) {
                      final provider = ref.read(appRiverpod);
                      final created = await provider.createAccount(
                        name: nameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                        role: selectedRole,
                      );

                      if (!context.mounted) return;
                      if (!created) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.backendSyncError ??
                                'تعذر تسجيل الحساب على السيرفر'),
                            backgroundColor: const Color(0xFFef4444),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'تم تسجيل حساب "${nameController.text}" على السيرفر بنجاح'),
                          backgroundColor: const Color(0xFF0ea5e9),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('تأكيد وتسجيل الحساب',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTag(
      String value, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0ea5e9) : const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF0ea5e9)
                  : const Color(0xFFe2e8f0)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748b),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
      ),
    );
  }

  Widget _buildStaffSummary(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF0369a1),
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(provider.totalStaffCount.toString(), 'إجمالي الطاقم'),
          _summaryItem(provider.activeStaffCount.toString(), 'نشط الآن'),
          _summaryItem('${(provider.averageStaffCompletion * 100).toInt()}%',
              'معدل الإنجاز'),
        ],
      ),
    );
  }

  static Widget _summaryItem(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildStaffCard(
      BuildContext context,
      WidgetRef ref,
      String id,
      String name,
      String role,
      double rate,
      String status,
      String time,
      String? imageUrl) {
    bool isOnline = status == 'online';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFf1f5f9))),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminStaffDetailScreen(
                  staffId: id,
                  name: name,
                  role: role,
                  rate: rate,
                  status: status,
                  time: time,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Hero(
                      tag: id,
                      child: GestureDetector(
                        onTap: () async {
                          final saved = await ref
                              .read(appRiverpod)
                              .pickAndSetStaffImage(id);
                          if (!context.mounted || saved == null) return;
                          final error = ref.read(appRiverpod).backendSyncError;
                          ScaffoldMessenger.of(context).showSnackBar(
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
                        child: Stack(
                          children: [
                            Builder(
                              builder: (context) {
                                final String? img = imageUrl;
                                final imageProvider = _staffImageProvider(img);
                                return CircleAvatar(
                                  backgroundColor: const Color(0xFFf0f9ff),
                                  radius: 22,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name.substring(0, 1)
                                              : 'م',
                                          style: const TextStyle(
                                            color: Color(0xFF0ea5e9),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0ea5e9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0f172a))),
                          Text(
                              role == 'Nurse'
                                  ? 'طاقم التمريض'
                                  : 'أخصائي اجتماعي',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(time,
                            style: const TextStyle(
                                color: Color(0xFF64748b), fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFFdcfce7)
                                  : const Color(0xFFf1f5f9),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(isOnline ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                  color: isOnline
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF64748b),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCompletionBar(rate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionBar(double rate) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('معدل إنجاز المهام اليومية',
                style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
            Text('${(rate * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0f172a))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: rate,
              backgroundColor: const Color(0xFFf1f5f9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF0ea5e9)),
              minHeight: 6),
        ),
      ],
    );
  }
}
